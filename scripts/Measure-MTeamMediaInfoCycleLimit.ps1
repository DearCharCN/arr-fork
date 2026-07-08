[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://api.m-team.cc',

    [string]$ApiToken = $env:MTEAM_API_TOKEN,

    [string]$TorrentId = '1202530',

    [ValidateRange(1, 3600)]
    [int]$IntervalSeconds = 1,

    [ValidateRange(1, 10000)]
    [int]$TotalRequestsTarget = 100,

    [ValidateRange(0, 10000)]
    [int]$SuccessTarget = 0,

    [ValidateRange(1, 1440)]
    [int]$InitialBackoffMinutes = 5,

    [ValidateRange(1, 1440)]
    [int]$BackoffIncrementMinutes = 1,

    [ValidateRange(1, 1440)]
    [int]$MaxBackoffMinutes = 120,

    [string]$OutDirectory = 'tmp\mteam-mediainfo-rate-limit'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiToken)) {
    throw 'Set MTEAM_API_TOKEN in the current shell or pass -ApiToken. Do not store the token in tracked files.'
}

if ([string]::IsNullOrWhiteSpace($TorrentId)) {
    throw 'TorrentId is required for this long-running probe.'
}

function Join-ApiUri {
    param(
        [string]$Root,
        [string]$Path
    )

    return $Root.TrimEnd('/') + '/' + $Path.TrimStart('/')
}

function Get-JsonValue {
    param(
        [object]$Value,
        [string[]]$Names
    )

    if ($null -eq $Value) {
        return $null
    }

    foreach ($name in $Names) {
        $property = $Value.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

function Invoke-MTeamWebRequest {
    param([string]$Uri)

    $headers = @{
        'x-api-key' = $ApiToken
        'Accept' = 'application/json'
        'User-Agent' = 'arr-fork-mteam-mediainfo-cycle-probe/1.0'
    }

    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Post -Headers $headers -TimeoutSec 30 -UseBasicParsing
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Content = [string]$response.Content
            Error = $null
        }
    } catch [System.Net.WebException] {
        $webResponse = $_.Exception.Response
        $content = ''
        $statusCode = 0

        if ($null -ne $webResponse) {
            $statusCode = [int]$webResponse.StatusCode
            $stream = $webResponse.GetResponseStream()
            if ($null -ne $stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                $content = $reader.ReadToEnd()
            }
        }

        return [pscustomobject]@{
            StatusCode = $statusCode
            Content = $content
            Error = $_.Exception.Message
        }
    }
}

function ConvertTo-ApiResult {
    param(
        [string]$Phase,
        [int]$Cycle,
        [int]$AttemptInCycle,
        [int]$TotalRequestNumber,
        [int]$PlannedDelaySeconds,
        [int]$BackoffMinutes,
        [datetime]$StartedAt,
        [double]$ElapsedMs,
        [object]$RawResponse
    )

    $message = $null
    $code = $null
    $dataLength = 0

    if (-not [string]::IsNullOrWhiteSpace($RawResponse.Content)) {
        try {
            $json = $RawResponse.Content | ConvertFrom-Json
            $message = [string](Get-JsonValue -Value $json -Names @('message', 'msg'))
            $code = Get-JsonValue -Value $json -Names @('code', 'status')
            $data = Get-JsonValue -Value $json -Names @('data')

            if ($data -is [string]) {
                $dataLength = $data.Length
            } elseif ($null -ne $data) {
                $dataLength = ($data | ConvertTo-Json -Depth 20 -Compress).Length
            }
        } catch {
            $message = 'non-json response'
        }
    }

    $tooFrequent = $false

    if (-not [string]::IsNullOrWhiteSpace($message)) {
        $traditionalFrequent = -join ([char]0x983B, [char]0x7E41)
        $simplifiedFrequent = -join ([char]0x9891, [char]0x7E41)
        $tooFrequent = $message.Contains($traditionalFrequent) -or $message.Contains($simplifiedFrequent)
    }

    if (-not $tooFrequent) {
        $combined = @($message, $RawResponse.Content, $RawResponse.Error) -join ' '
        $tooFrequent = $combined -match 'too\s*frequent|rate\s*limit'
    }

    $success = -not $tooFrequent -and $RawResponse.StatusCode -ge 200 -and $RawResponse.StatusCode -lt 300 -and $dataLength -gt 0
    $classification = if ($tooFrequent) {
        'too_frequent'
    } elseif ($success) {
        'success'
    } else {
        'api_error'
    }

    return [pscustomobject]@{
        phase = $Phase
        cycle = $Cycle
        attemptInCycle = $AttemptInCycle
        totalRequestNumber = $TotalRequestNumber
        plannedDelaySeconds = $PlannedDelaySeconds
        backoffMinutes = $BackoffMinutes
        startedAtLocal = $StartedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
        startedAtUtc = $StartedAt.ToUniversalTime().ToString('o')
        elapsedMs = [math]::Round($ElapsedMs, 1)
        statusCode = $RawResponse.StatusCode
        apiCode = if ($null -eq $code) { $null } else { [string]$code }
        apiMessage = if ([string]::IsNullOrWhiteSpace($message)) { $null } else { $message }
        dataLength = $dataLength
        classification = $classification
    }
}

function Invoke-MediaInfoProbe {
    param(
        [string]$Phase,
        [int]$Cycle,
        [int]$AttemptInCycle,
        [int]$PlannedDelaySeconds,
        [int]$BackoffMinutes
    )

    if ($PlannedDelaySeconds -gt 0) {
        Start-Sleep -Seconds $PlannedDelaySeconds
    }

    $script:TotalMediaInfoRequests++
    $startedAt = Get-Date
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $uri = (Join-ApiUri $BaseUrl '/api/torrent/mediaInfo') + '?id=' + [Uri]::EscapeDataString($TorrentId)
    $raw = Invoke-MTeamWebRequest -Uri $uri
    $watch.Stop()

    $result = ConvertTo-ApiResult `
        -Phase $Phase `
        -Cycle $Cycle `
        -AttemptInCycle $AttemptInCycle `
        -TotalRequestNumber $script:TotalMediaInfoRequests `
        -PlannedDelaySeconds $PlannedDelaySeconds `
        -BackoffMinutes $BackoffMinutes `
        -StartedAt $startedAt `
        -ElapsedMs $watch.Elapsed.TotalMilliseconds `
        -RawResponse $raw

    $script:Results.Add($result) | Out-Null
    Write-Host ("{0,-12} total=#{1,-3} cycle={2,-2} attempt={3,-3} delay={4,4}s backoff={5,3}m {6,-13} http={7,-3} msg={8}" -f $result.phase, $result.totalRequestNumber, $result.cycle, $result.attemptInCycle, $result.plannedDelaySeconds, $result.backoffMinutes, $result.classification, $result.statusCode, $result.apiMessage)

    return $result
}

$cwd = [System.IO.Path]::GetFullPath((Get-Location).Path)
$fullOutDirectory = [System.IO.Path]::GetFullPath($OutDirectory)
if (-not $fullOutDirectory.StartsWith($cwd, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside current workspace: $fullOutDirectory"
}

New-Item -ItemType Directory -Force -Path $fullOutDirectory | Out-Null

$script:Results = New-Object System.Collections.Generic.List[object]
$script:TotalMediaInfoRequests = 0
$script:TotalSuccessfulMediaInfoRequests = 0
$cycle = 1
$attemptInCycle = 0
$mode = 'active'
$currentBackoffMinutes = $InitialBackoffMinutes
$runStartedAt = Get-Date

Write-Host "Using BaseUrl=$BaseUrl torrentId=$TorrentId"
if ($SuccessTarget -gt 0) {
    Write-Host "Target successful mediaInfo requests: $SuccessTarget"
    Write-Host "Safety max total mediaInfo requests: $TotalRequestsTarget"
} else {
    Write-Host "Target mediaInfo requests: $TotalRequestsTarget"
}

Write-Host "Active interval: ${IntervalSeconds}s; initial backoff: ${InitialBackoffMinutes}m; increment: ${BackoffIncrementMinutes}m"
Write-Host "Results will be written under $fullOutDirectory"

while (
    $script:TotalMediaInfoRequests -lt $TotalRequestsTarget -and
    (
        ($SuccessTarget -le 0) -or
        ($script:TotalSuccessfulMediaInfoRequests -lt $SuccessTarget)
    )
) {
    if ($mode -eq 'active') {
        $attemptInCycle++
        $delay = if ($attemptInCycle -eq 1) { 0 } else { $IntervalSeconds }
        $result = Invoke-MediaInfoProbe -Phase 'active' -Cycle $cycle -AttemptInCycle $attemptInCycle -PlannedDelaySeconds $delay -BackoffMinutes 0

        if ($result.classification -eq 'success') {
            $script:TotalSuccessfulMediaInfoRequests++
        } else {
            $mode = 'backoff'
            $currentBackoffMinutes = $InitialBackoffMinutes
        }

        continue
    }

    if ($mode -eq 'backoff') {
        $delaySeconds = $currentBackoffMinutes * 60
        $result = Invoke-MediaInfoProbe -Phase 'backoff_check' -Cycle $cycle -AttemptInCycle 0 -PlannedDelaySeconds $delaySeconds -BackoffMinutes $currentBackoffMinutes

        if ($result.classification -eq 'success') {
            $script:TotalSuccessfulMediaInfoRequests++
            $cycle++
            $attemptInCycle = 1
            $mode = 'active'
            $currentBackoffMinutes = $InitialBackoffMinutes
        } else {
            $currentBackoffMinutes = [math]::Min($currentBackoffMinutes + $BackoffIncrementMinutes, $MaxBackoffMinutes)
        }
    }
}

$runEndedAt = Get-Date
$resultArray = @($script:Results | ForEach-Object { $_ })
$totalSuccesses = @($resultArray | Where-Object { $_.classification -eq 'success' }).Count
$totalTooFrequent = @($resultArray | Where-Object { $_.classification -eq 'too_frequent' }).Count
$failureEvents = @($resultArray | Where-Object { $_.classification -ne 'success' })
$cyclesCompleted = @($resultArray | Where-Object { $_.phase -eq 'active' } | Select-Object -ExpandProperty cycle -Unique).Count

$summary = [pscustomobject]@{
    baseUrl = $BaseUrl
    endpoint = '/api/torrent/mediaInfo'
    torrentId = $TorrentId
    startedAtLocal = $runStartedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    endedAtLocal = $runEndedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    durationSeconds = [math]::Round(($runEndedAt - $runStartedAt).TotalSeconds, 1)
    intervalSeconds = $IntervalSeconds
    totalRequestsTarget = $TotalRequestsTarget
    successTarget = $SuccessTarget
    totalMediaInfoRequests = $script:TotalMediaInfoRequests
    totalSuccesses = $totalSuccesses
    totalTooFrequent = $totalTooFrequent
    cyclesCompleted = $cyclesCompleted
    initialBackoffMinutes = $InitialBackoffMinutes
    backoffIncrementMinutes = $BackoffIncrementMinutes
    maxBackoffMinutes = $MaxBackoffMinutes
    failures = $failureEvents
}

$stamp = $runStartedAt.ToString('yyyyMMdd-HHmmss')
$jsonPath = Join-Path $fullOutDirectory "mteam-mediainfo-cycle-$stamp.json"
$csvPath = Join-Path $fullOutDirectory "mteam-mediainfo-cycle-$stamp.csv"

[pscustomobject]@{
    summary = $summary
    results = $resultArray
} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$resultArray | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Wrote JSON summary: $jsonPath"
Write-Host "Wrote CSV results:  $csvPath"
Write-Host "Summary:"
$summary | ConvertTo-Json -Depth 20
