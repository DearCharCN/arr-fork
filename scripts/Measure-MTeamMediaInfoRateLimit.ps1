[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://api.m-team.cc',

    [string]$ApiToken = $env:MTEAM_API_TOKEN,

    [string]$TorrentId,

    [string]$Keyword = 'Titanic',

    [ValidateRange(1, 50)]
    [int]$BurstMaxRequests = 8,

    [ValidateRange(1, 20)]
    [int]$IntervalAttempts = 3,

    [int[]]$IntervalsSeconds = @(3, 5, 8, 10, 15, 20),

    [ValidateRange(5, 300)]
    [int]$RecoveryProbeEverySeconds = 20,

    [ValidateRange(30, 1800)]
    [int]$RecoveryMaxSeconds = 300,

    [string]$OutDirectory = 'tmp\mteam-mediainfo-rate-limit',

    [switch]$BaselineOnly,

    [switch]$SkipBurst,

    [switch]$SkipIntervalSweep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiToken)) {
    throw 'Set MTEAM_API_TOKEN in the current shell or pass -ApiToken. Do not store the token in tracked files.'
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
    param(
        [string]$Uri,
        [string]$Method = 'Post',
        [string]$ContentType,
        [object]$Body
    )

    $headers = @{
        'x-api-key' = $ApiToken
        'Accept' = 'application/json'
        'User-Agent' = 'arr-fork-mteam-mediainfo-rate-probe/1.0'
    }

    $parameters = @{
        Uri = $Uri
        Method = $Method
        Headers = $headers
        TimeoutSec = 30
        UseBasicParsing = $true
    }

    if ($ContentType) {
        $parameters.ContentType = $ContentType
    }

    if ($null -ne $Body) {
        $parameters.Body = $Body
    }

    try {
        $response = Invoke-WebRequest @parameters
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
        [int]$Attempt,
        [int]$PlannedDelaySeconds,
        [datetime]$StartedAt,
        [double]$ElapsedMs,
        [object]$RawResponse
    )

    $json = $null
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

    $combined = @($message, $RawResponse.Content, $RawResponse.Error) -join ' '
    $tooFrequent = $false

    if (-not [string]::IsNullOrWhiteSpace($message)) {
        $traditionalFrequent = -join ([char]0x983B, [char]0x7E41)
        $simplifiedFrequent = -join ([char]0x9891, [char]0x7E41)
        $tooFrequent = $message.Contains($traditionalFrequent) -or $message.Contains($simplifiedFrequent)
    }

    if (-not $tooFrequent) {
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
        attempt = $Attempt
        plannedDelaySeconds = $PlannedDelaySeconds
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
        [int]$Attempt,
        [int]$PlannedDelaySeconds
    )

    if ($PlannedDelaySeconds -gt 0) {
        Start-Sleep -Seconds $PlannedDelaySeconds
    }

    $startedAt = Get-Date
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $uri = (Join-ApiUri $BaseUrl '/api/torrent/mediaInfo') + '?id=' + [Uri]::EscapeDataString($TorrentId)
    $raw = Invoke-MTeamWebRequest -Uri $uri -Method Post
    $watch.Stop()

    $result = ConvertTo-ApiResult -Phase $Phase -Attempt $Attempt -PlannedDelaySeconds $PlannedDelaySeconds -StartedAt $startedAt -ElapsedMs $watch.Elapsed.TotalMilliseconds -RawResponse $raw
    $script:Results.Add($result) | Out-Null
    Write-Host ("{0,-18} #{1,-2} delay={2,3}s {3,-13} http={4,-3} msg={5}" -f $result.phase, $result.attempt, $result.plannedDelaySeconds, $result.classification, $result.statusCode, $result.apiMessage)

    return $result
}

function Find-TorrentId {
    $endpoint = Join-ApiUri $BaseUrl '/api/torrent/search'
    $body = @{
        mode = 'Normal'
        categories = @()
        pageNumber = 1
        pageSize = 1
    }

    if (-not [string]::IsNullOrWhiteSpace($Keyword)) {
        $body.keyword = $Keyword
    }

    $raw = Invoke-MTeamWebRequest -Uri $endpoint -Method Post -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 10)

    if ($raw.StatusCode -lt 200 -or $raw.StatusCode -ge 300) {
        throw "Search failed with HTTP $($raw.StatusCode)."
    }

    $json = $raw.Content | ConvertFrom-Json
    $data = Get-JsonValue -Value $json -Names @('data')
    $items = Get-JsonValue -Value $data -Names @('data', 'list', 'records')

    if ($null -eq $items -or @($items).Count -lt 1) {
        throw "Search returned no torrents for keyword '$Keyword'. Pass -TorrentId explicitly."
    }

    $first = @($items)[0]
    $id = Get-JsonValue -Value $first -Names @('id', 'tid', 'torrentId')

    if ([string]::IsNullOrWhiteSpace([string]$id)) {
        throw "Search result did not contain an id. Pass -TorrentId explicitly."
    }

    return [string]$id
}

function Wait-ForRecovery {
    param(
        [string]$Phase,
        [int]$ProbeEverySeconds,
        [int]$MaxSeconds
    )

    $elapsed = 0
    $attempt = 0

    while ($elapsed -lt $MaxSeconds) {
        $attempt++
        $result = Invoke-MediaInfoProbe -Phase $Phase -Attempt $attempt -PlannedDelaySeconds $ProbeEverySeconds
        $elapsed += $ProbeEverySeconds

        if ($result.classification -eq 'success') {
            return [pscustomobject]@{
                recovered = $true
                seconds = $elapsed
            }
        }
    }

    return [pscustomobject]@{
        recovered = $false
        seconds = $elapsed
    }
}

$cwd = [System.IO.Path]::GetFullPath((Get-Location).Path)
$fullOutDirectory = [System.IO.Path]::GetFullPath($OutDirectory)
if (-not $fullOutDirectory.StartsWith($cwd, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside current workspace: $fullOutDirectory"
}

New-Item -ItemType Directory -Force -Path $fullOutDirectory | Out-Null

if ([string]::IsNullOrWhiteSpace($TorrentId)) {
    $TorrentId = Find-TorrentId
}

$script:Results = New-Object System.Collections.Generic.List[object]
$runStartedAt = Get-Date
$rateLimitEvents = New-Object System.Collections.Generic.List[object]
$canContinue = $true

Write-Host "Using BaseUrl=$BaseUrl torrentId=$TorrentId keyword=$Keyword"
Write-Host "Results will be written under $fullOutDirectory"

$baseline = Invoke-MediaInfoProbe -Phase 'baseline' -Attempt 1 -PlannedDelaySeconds 0

if ($BaselineOnly) {
    Write-Host "BaselineOnly was set; skipping recovery, burst, and interval sweep."
    $canContinue = $false
} elseif ($baseline.classification -eq 'too_frequent') {
    Write-Host "Already rate limited at baseline; measuring recovery before burst."
    $recovery = Wait-ForRecovery -Phase 'baseline_recovery' -ProbeEverySeconds $RecoveryProbeEverySeconds -MaxSeconds $RecoveryMaxSeconds
    $canContinue = $recovery.recovered
    $rateLimitEvents.Add([pscustomobject]@{
        phase = 'baseline'
        recovered = $recovery.recovered
        recoverySeconds = $recovery.seconds
    }) | Out-Null

    if (-not $canContinue) {
        Write-Host "Rate limit did not recover within $RecoveryMaxSeconds seconds; skipping burst and interval sweep."
    }
}

if ($canContinue -and -not $SkipBurst) {
    $burstLimitedAt = $null

    for ($i = 1; $i -le $BurstMaxRequests; $i++) {
        $result = Invoke-MediaInfoProbe -Phase 'burst_zero_delay' -Attempt $i -PlannedDelaySeconds 0
        if ($result.classification -eq 'too_frequent') {
            $burstLimitedAt = $i
            $rateLimitEvents.Add([pscustomobject]@{
                phase = 'burst_zero_delay'
                limitedAtAttempt = $i
            }) | Out-Null
            break
        }
    }

    if ($null -ne $burstLimitedAt) {
        Write-Host "Burst hit rate limit at attempt $burstLimitedAt; measuring recovery."
        $recovery = Wait-ForRecovery -Phase 'burst_recovery' -ProbeEverySeconds $RecoveryProbeEverySeconds -MaxSeconds $RecoveryMaxSeconds
        $rateLimitEvents.Add([pscustomobject]@{
            phase = 'burst_recovery'
            recovered = $recovery.recovered
            recoverySeconds = $recovery.seconds
        }) | Out-Null
    }
}

if ($canContinue -and -not $SkipIntervalSweep) {
    foreach ($interval in $IntervalsSeconds) {
        $limited = $false

        for ($i = 1; $i -le $IntervalAttempts; $i++) {
            $result = Invoke-MediaInfoProbe -Phase "interval_${interval}s" -Attempt $i -PlannedDelaySeconds $interval
            if ($result.classification -eq 'too_frequent') {
                $limited = $true
                $rateLimitEvents.Add([pscustomobject]@{
                    phase = "interval_${interval}s"
                    limitedAtAttempt = $i
                }) | Out-Null
                break
            }
        }

        if ($limited) {
            Write-Host "Interval ${interval}s hit rate limit; measuring recovery before next interval."
            $recovery = Wait-ForRecovery -Phase "interval_${interval}s_recovery" -ProbeEverySeconds $RecoveryProbeEverySeconds -MaxSeconds $RecoveryMaxSeconds
            $rateLimitEvents.Add([pscustomobject]@{
                phase = "interval_${interval}s_recovery"
                recovered = $recovery.recovered
                recoverySeconds = $recovery.seconds
            }) | Out-Null
        }
    }
}

$runEndedAt = Get-Date
$safeIntervals = @()

if ($canContinue -and -not $SkipIntervalSweep) {
    foreach ($interval in $IntervalsSeconds) {
        $phaseName = "interval_${interval}s"
        $phaseResults = @($script:Results | Where-Object { $_.phase -eq $phaseName })
        if ($phaseResults.Count -eq $IntervalAttempts -and -not ($phaseResults | Where-Object { $_.classification -eq 'too_frequent' })) {
            $safeIntervals += $interval
        }
    }
}

$firstTooFrequentResult = $script:Results | Where-Object { $_.classification -eq 'too_frequent' } | Select-Object -First 1
$firstTooFrequent = $null
if ($null -ne $firstTooFrequentResult) {
    $firstTooFrequent = [pscustomobject]@{
        phase = $firstTooFrequentResult.phase
        attempt = $firstTooFrequentResult.attempt
        plannedDelaySeconds = $firstTooFrequentResult.plannedDelaySeconds
        startedAtLocal = $firstTooFrequentResult.startedAtLocal
        apiMessage = $firstTooFrequentResult.apiMessage
    }
}

$totalSuccesses = @($script:Results | Where-Object { $_.classification -eq 'success' }).Count
$totalTooFrequent = @($script:Results | Where-Object { $_.classification -eq 'too_frequent' }).Count
$rateLimitEventArray = @($rateLimitEvents | ForEach-Object { $_ })
$resultArray = @($script:Results | ForEach-Object { $_ })

$summary = [pscustomobject]@{
    baseUrl = $BaseUrl
    endpoint = '/api/torrent/mediaInfo'
    torrentId = $TorrentId
    keyword = $Keyword
    startedAtLocal = $runStartedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    endedAtLocal = $runEndedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    durationSeconds = [math]::Round(($runEndedAt - $runStartedAt).TotalSeconds, 1)
    burstMaxRequests = $BurstMaxRequests
    intervalAttempts = $IntervalAttempts
    intervalsSeconds = $IntervalsSeconds
    recoveryProbeEverySeconds = $RecoveryProbeEverySeconds
    recoveryMaxSeconds = $RecoveryMaxSeconds
    totalMediaInfoRequests = $script:Results.Count
    totalSuccesses = $totalSuccesses
    totalTooFrequent = $totalTooFrequent
    firstTooFrequent = $firstTooFrequent
    sampledSafeIntervalsSeconds = @($safeIntervals)
    rateLimitEvents = $rateLimitEventArray
}

$stamp = $runStartedAt.ToString('yyyyMMdd-HHmmss')
$jsonPath = Join-Path $fullOutDirectory "mteam-mediainfo-rate-$stamp.json"
$csvPath = Join-Path $fullOutDirectory "mteam-mediainfo-rate-$stamp.csv"

[pscustomobject]@{
    summary = $summary
    results = $resultArray
} | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$resultArray | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Wrote JSON summary: $jsonPath"
Write-Host "Wrote CSV results:  $csvPath"
Write-Host "Summary:"
$summary | ConvertTo-Json -Depth 20
