[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://api.m-team.cc',

    [string]$ApiToken = $env:MTEAM_API_TOKEN,

    [Parameter(Mandatory = $true)]
    [string]$TorrentId,

    [ValidateRange(1, 100000)]
    [int]$SuccessTarget = 500,

    [ValidateRange(1, 3600)]
    [int]$GlobalRequestIntervalSeconds = 10,

    [ValidateRange(1, 3600)]
    [int]$PerEndpointIntervalSeconds = 20,

    [ValidateRange(1, 1440)]
    [int]$EndpointCooldownMinutes = 12,

    [ValidateRange(1, 100000)]
    [int]$MaxTotalRequests = 1000,

    [string]$OutDirectory = 'tmp\mteam-mediainfo-rate-limit'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiToken)) {
    throw 'MTEAM_API_TOKEN is not set. Set it in the environment before running this probe.'
}

function Join-ApiUri {
    param(
        [string]$Base,
        [string]$Path
    )

    return $Base.TrimEnd('/') + '/' + $Path.TrimStart('/')
}

function Test-RateLimitMessage {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return (
        $Message -match 'too frequent' -or
        $Message -like '*頻繁*' -or
        $Message -like '*频繁*'
    )
}

function Invoke-MTeamWebRequest {
    param(
        [string]$Uri,
        [string]$ApiToken
    )

    $headers = @{
        'x-api-key' = $ApiToken
        'Accept' = 'application/json'
        'User-Agent' = 'arr-fork-mteam-dual-endpoint-rate-probe/1.0'
    }

    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Post -Headers $headers -TimeoutSec 30 -UseBasicParsing

        return [pscustomobject]@{
            statusCode = [int]$response.StatusCode
            content = $response.Content
            transportError = $null
        }
    } catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
            } catch {
                $statusCode = $null
            }
        }

        return [pscustomobject]@{
            statusCode = $statusCode
            content = $null
            transportError = $_.Exception.Message
        }
    }
}

function ConvertTo-ProbeResult {
    param(
        [string]$EndpointName,
        [string]$EndpointPath,
        [int]$EndpointAttempt,
        [int]$TotalRequestNumber,
        [int]$SuccessTotalBefore,
        [datetime]$StartedAt,
        [double]$ElapsedMs,
        [object]$RawResponse
    )

    $apiCode = $null
    $apiMessage = $null
    $dataLength = 0
    $mediaInfoLength = 0
    $classification = 'transport_error'
    $parseError = $null

    if ($RawResponse.content) {
        try {
            $json = $RawResponse.content | ConvertFrom-Json

            if ($null -ne $json.code) {
                $apiCode = [string]$json.code
            }

            if ($null -ne $json.message) {
                $apiMessage = [string]$json.message
            }

            if ($null -ne $json.data) {
                if ($json.data -is [string]) {
                    $dataLength = $json.data.Length
                    $mediaInfoLength = $dataLength
                } else {
                    $dataJson = $json.data | ConvertTo-Json -Depth 20 -Compress
                    $dataLength = $dataJson.Length

                    if ($null -ne $json.data.mediainfo) {
                        $mediaInfoLength = ([string]$json.data.mediainfo).Length
                    } elseif ($null -ne $json.data.mediaInfo) {
                        $mediaInfoLength = ([string]$json.data.mediaInfo).Length
                    }
                }
            }

            if ($apiMessage -eq 'SUCCESS' -and ($dataLength -gt 0 -or $mediaInfoLength -gt 0)) {
                $classification = 'success'
            } elseif (Test-RateLimitMessage -Message $apiMessage) {
                $classification = 'too_frequent'
            } elseif ($apiCode -eq '1' -and $apiMessage -ne 'SUCCESS' -and $dataLength -eq 0 -and $mediaInfoLength -eq 0) {
                $classification = 'too_frequent'
            } elseif ($RawResponse.statusCode -ge 200 -and $RawResponse.statusCode -lt 300) {
                $classification = 'api_non_success'
            } else {
                $classification = 'http_error'
            }
        } catch {
            $classification = 'parse_error'
            $parseError = $_.Exception.Message
        }
    }

    return [pscustomobject]@{
        endpoint = $EndpointName
        endpointPath = $EndpointPath
        endpointAttempt = $EndpointAttempt
        totalRequestNumber = $TotalRequestNumber
        successTotalBefore = $SuccessTotalBefore
        startedAtLocal = $StartedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        startedAtUtc = $StartedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
        elapsedMs = [math]::Round($ElapsedMs, 1)
        statusCode = $RawResponse.statusCode
        apiCode = $apiCode
        apiMessage = $apiMessage
        dataLength = $dataLength
        mediaInfoLength = $mediaInfoLength
        classification = $classification
        transportError = $RawResponse.transportError
        parseError = $parseError
    }
}

function New-EndpointState {
    param(
        [string]$Name,
        [string]$Path,
        [datetime]$NextDueAt
    )

    return [pscustomobject]@{
        name = $Name
        path = $Path
        nextDueAt = $NextDueAt
        coolingUntil = $null
        requests = 0
        successes = 0
        tooFrequent = 0
        firstTooFrequentAtRequest = $null
        lastClassification = $null
    }
}

$fullOutDirectory = if ([System.IO.Path]::IsPathRooted($OutDirectory)) {
    $OutDirectory
} else {
    Join-Path (Get-Location) $OutDirectory
}

New-Item -ItemType Directory -Force -Path $fullOutDirectory | Out-Null

$runStartedAt = Get-Date
$endpoints = @(
    (New-EndpointState -Name 'mediaInfo' -Path '/api/torrent/mediaInfo' -NextDueAt $runStartedAt),
    (New-EndpointState -Name 'detail' -Path '/api/torrent/detail' -NextDueAt $runStartedAt.AddSeconds($GlobalRequestIntervalSeconds))
)

$script:Results = New-Object System.Collections.Generic.List[object]
$script:CooldownEvents = New-Object System.Collections.Generic.List[object]
$totalRequests = 0
$totalSuccesses = 0
$totalTooFrequent = 0
$stopReason = 'success_target_reached'
$nextGlobalRequestAt = $runStartedAt

Write-Host "Using BaseUrl=$BaseUrl torrentId=$TorrentId"
Write-Host "Success target: $SuccessTarget; safety max total requests: $MaxTotalRequests"
Write-Host "Global request interval: ${GlobalRequestIntervalSeconds}s; per-endpoint interval: ${PerEndpointIntervalSeconds}s"
Write-Host "Endpoint cooldown on rate limit: ${EndpointCooldownMinutes}m"
Write-Host "Results will be written under $fullOutDirectory"

while ($totalSuccesses -lt $SuccessTarget -and $totalRequests -lt $MaxTotalRequests) {
    $now = Get-Date

    if ($now -lt $nextGlobalRequestAt) {
        $sleepSeconds = [math]::Ceiling(($nextGlobalRequestAt - $now).TotalSeconds)
        if ($sleepSeconds -gt 0) {
            Start-Sleep -Seconds $sleepSeconds
        }
    }

    $now = Get-Date
    $eligible = @($endpoints | Where-Object { $_.nextDueAt -le $now } | Sort-Object nextDueAt)

    if ($eligible.Count -eq 0) {
        $nextDueAt = @($endpoints | Sort-Object nextDueAt | Select-Object -First 1).nextDueAt
        $sleepSeconds = [math]::Ceiling(($nextDueAt - $now).TotalSeconds)
        if ($sleepSeconds -gt 0) {
            Start-Sleep -Seconds $sleepSeconds
        }
        continue
    }

    $endpoint = $eligible[0]
    $endpoint.requests++
    $totalRequests++
    $startedAt = Get-Date
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $uri = (Join-ApiUri -Base $BaseUrl -Path $endpoint.path) + '?id=' + [Uri]::EscapeDataString($TorrentId)
    $raw = Invoke-MTeamWebRequest -Uri $uri -ApiToken $ApiToken
    $watch.Stop()

    $result = ConvertTo-ProbeResult `
        -EndpointName $endpoint.name `
        -EndpointPath $endpoint.path `
        -EndpointAttempt $endpoint.requests `
        -TotalRequestNumber $totalRequests `
        -SuccessTotalBefore $totalSuccesses `
        -StartedAt $startedAt `
        -ElapsedMs $watch.Elapsed.TotalMilliseconds `
        -RawResponse $raw

    if ($result.classification -eq 'success') {
        $endpoint.successes++
        $totalSuccesses++
        $endpoint.nextDueAt = $startedAt.AddSeconds($PerEndpointIntervalSeconds)
        $endpoint.coolingUntil = $null
    } elseif ($result.classification -eq 'too_frequent') {
        $endpoint.tooFrequent++
        $totalTooFrequent++
        if ($null -eq $endpoint.firstTooFrequentAtRequest) {
            $endpoint.firstTooFrequentAtRequest = $endpoint.requests
        }

        $coolingUntil = $startedAt.AddMinutes($EndpointCooldownMinutes)
        $endpoint.coolingUntil = $coolingUntil
        $endpoint.nextDueAt = $coolingUntil

        $script:CooldownEvents.Add([pscustomobject]@{
            endpoint = $endpoint.name
            totalRequestNumber = $totalRequests
            endpointAttempt = $endpoint.requests
            startedAtLocal = $startedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            coolingUntilLocal = $coolingUntil.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            cooldownMinutes = $EndpointCooldownMinutes
            apiMessage = $result.apiMessage
        })
    } else {
        $endpoint.nextDueAt = $startedAt.AddSeconds($PerEndpointIntervalSeconds)
    }

    $endpoint.lastClassification = $result.classification
    $script:Results.Add($result)
    $nextGlobalRequestAt = $startedAt.AddSeconds($GlobalRequestIntervalSeconds)

    Write-Host (
        "{0,-9} total=#{1,-4} endpointAttempt=#{2,-4} successTotal={3,-4} class={4,-13} http={5} msg={6}" -f `
            $endpoint.name,
            $totalRequests,
            $endpoint.requests,
            $totalSuccesses,
            $result.classification,
            $result.statusCode,
            $result.apiMessage
    )
}

if ($totalSuccesses -lt $SuccessTarget) {
    if ($totalRequests -ge $MaxTotalRequests) {
        $stopReason = 'max_total_requests_reached'
    } else {
        $stopReason = 'stopped_before_success_target'
    }
}

$runEndedAt = Get-Date
$resultArray = @($script:Results.ToArray())
$cooldownArray = @($script:CooldownEvents.ToArray())

$endpointSummaries = @($endpoints | ForEach-Object {
    [pscustomobject]@{
        endpoint = $_.name
        requests = $_.requests
        successes = $_.successes
        tooFrequent = $_.tooFrequent
        firstTooFrequentAtRequest = $_.firstTooFrequentAtRequest
        lastClassification = $_.lastClassification
        nextDueAtLocal = $_.nextDueAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        coolingUntilLocal = if ($null -ne $_.coolingUntil) { $_.coolingUntil.ToString('yyyy-MM-ddTHH:mm:ss.fffK') } else { $null }
    }
})

$summary = [pscustomobject]@{
    baseUrl = $BaseUrl
    endpoints = @('/api/torrent/mediaInfo', '/api/torrent/detail')
    torrentId = $TorrentId
    startedAtLocal = $runStartedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    endedAtLocal = $runEndedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    durationSeconds = [math]::Round(($runEndedAt - $runStartedAt).TotalSeconds, 1)
    successTarget = $SuccessTarget
    stopReason = $stopReason
    globalRequestIntervalSeconds = $GlobalRequestIntervalSeconds
    perEndpointIntervalSeconds = $PerEndpointIntervalSeconds
    endpointCooldownMinutes = $EndpointCooldownMinutes
    maxTotalRequests = $MaxTotalRequests
    totalRequests = $totalRequests
    totalSuccesses = $totalSuccesses
    totalTooFrequent = $totalTooFrequent
    endpointSummaries = $endpointSummaries
    cooldownEvents = $cooldownArray
}

$stamp = $runStartedAt.ToString('yyyyMMdd-HHmmss')
$jsonPath = Join-Path $fullOutDirectory "mteam-dual-endpoint-rate-$stamp.json"
$csvPath = Join-Path $fullOutDirectory "mteam-dual-endpoint-rate-$stamp.csv"

[pscustomobject]@{
    summary = $summary
    results = $resultArray
} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$resultArray | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Wrote JSON summary: $jsonPath"
Write-Host "Wrote CSV results:  $csvPath"
Write-Host 'Summary:'
$summary | ConvertTo-Json -Depth 20
