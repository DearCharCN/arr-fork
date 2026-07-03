[CmdletBinding()]
param(
    [ValidateSet('Profile', 'Search', 'Detail', 'DownloadToken')]
    [string]$Operation = 'Search',

    [string]$BaseUrl = 'https://api.m-team.cc',

    [string]$ApiToken = $env:MTEAM_API_TOKEN,

    [string]$Keyword,

    [string[]]$Categories = @(),

    [ValidateSet('Normal', 'Adult')]
    [string]$Mode = 'Normal',

    [int]$PageNumber = 1,

    [ValidateRange(1, 100)]
    [int]$PageSize = 1,

    [string]$Imdb,

    [string]$Discount,

    [string]$TorrentId,

    [ValidateSet('QueryPost', 'JsonPost', 'Get')]
    [string]$DetailTransport = 'QueryPost',

    [string]$OutFile,

    [switch]$AllowDownloadToken
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

function Invoke-MTeamJsonPost {
    param(
        [string]$Path,
        [hashtable]$Body,
        [hashtable]$Headers
    )

    $json = $Body | ConvertTo-Json -Depth 20

    return Invoke-RestMethod `
        -Uri (Join-ApiUri $BaseUrl $Path) `
        -Method Post `
        -Headers $Headers `
        -ContentType 'application/json' `
        -Body $json
}

function ConvertTo-RedactedObject {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Array]) {
        return @($Value | ForEach-Object { ConvertTo-RedactedObject $_ })
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $output = [ordered]@{}

        foreach ($key in $Value.Keys) {
            $name = [string]$key
            if ($name -match '(?i)(api.?key|token|pass|passkey|cookie|secret|auth|email|mail|username|user.?name|member.?id|uid|ip)') {
                $output[$name] = '[redacted]'
            } else {
                $output[$name] = ConvertTo-RedactedObject $Value[$key]
            }
        }

        return [pscustomobject]$output
    }

    if ($Value -is [pscustomobject]) {
        $output = [ordered]@{}

        foreach ($property in $Value.PSObject.Properties) {
            if ($property.Name -match '(?i)(api.?key|token|pass|passkey|cookie|secret|auth|email|mail|username|user.?name|member.?id|uid|ip)') {
                $output[$property.Name] = '[redacted]'
            } else {
                $output[$property.Name] = ConvertTo-RedactedObject $property.Value
            }
        }

        return [pscustomobject]$output
    }

    return $Value
}

function Write-ProbeOutput {
    param(
        [object]$Response,
        [string]$Endpoint,
        [string]$Method
    )

    $payload = [ordered]@{
        operation = $Operation
        method = $Method
        endpoint = $Endpoint
        baseUrl = $BaseUrl
        capturedAtUtc = [DateTime]::UtcNow.ToString('o')
        response = ConvertTo-RedactedObject $Response
    }

    $json = $payload | ConvertTo-Json -Depth 100

    if ($OutFile) {
        $cwd = [System.IO.Path]::GetFullPath((Get-Location).Path)
        $fullOut = [System.IO.Path]::GetFullPath($OutFile)

        if (-not $fullOut.StartsWith($cwd, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to write outside current workspace: $fullOut"
        }

        $parent = Split-Path -Parent $fullOut
        if ($parent) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }

        Set-Content -LiteralPath $fullOut -Value $json -Encoding UTF8
        Write-Host "Wrote sanitized response to $fullOut"
    }

    $json
}

$headers = @{
    'x-api-key' = $ApiToken
    'Accept' = 'application/json'
    'User-Agent' = 'arr-fork-mteam-api-probe/1.0'
}

switch ($Operation) {
    'Profile' {
        $endpoint = '/api/member/profile'
        $response = Invoke-RestMethod -Uri (Join-ApiUri $BaseUrl $endpoint) -Method Post -Headers $headers
        Write-ProbeOutput -Response $response -Endpoint $endpoint -Method 'POST'
    }

    'Search' {
        $endpoint = '/api/torrent/search'
        $body = @{
            mode = $Mode
            categories = $Categories
            pageNumber = $PageNumber
            pageSize = $PageSize
        }

        if (-not [string]::IsNullOrWhiteSpace($Keyword)) {
            $body.keyword = $Keyword
        }

        if (-not [string]::IsNullOrWhiteSpace($Imdb)) {
            $body.imdb = $Imdb
        }

        if (-not [string]::IsNullOrWhiteSpace($Discount)) {
            $body.discount = $Discount
        }

        $response = Invoke-MTeamJsonPost -Path $endpoint -Body $body -Headers $headers
        Write-ProbeOutput -Response $response -Endpoint $endpoint -Method 'POST'
    }

    'Detail' {
        if ([string]::IsNullOrWhiteSpace($TorrentId)) {
            throw 'Detail requires -TorrentId.'
        }

        $endpoint = '/api/torrent/detail'

        switch ($DetailTransport) {
            'QueryPost' {
                $uri = (Join-ApiUri $BaseUrl $endpoint) + '?id=' + [Uri]::EscapeDataString($TorrentId)
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
                Write-ProbeOutput -Response $response -Endpoint "${endpoint}?id=<torrent id>" -Method 'POST'
            }
            'JsonPost' {
                $response = Invoke-MTeamJsonPost -Path $endpoint -Body @{ id = $TorrentId } -Headers $headers
                Write-ProbeOutput -Response $response -Endpoint $endpoint -Method 'POST'
            }
            'Get' {
                $uri = (Join-ApiUri $BaseUrl $endpoint) + '?id=' + [Uri]::EscapeDataString($TorrentId)
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
                Write-ProbeOutput -Response $response -Endpoint "${endpoint}?id=<torrent id>" -Method 'GET'
            }
        }
    }

    'DownloadToken' {
        if (-not $AllowDownloadToken) {
            throw 'DownloadToken can count against download-related limits. Re-run with -AllowDownloadToken if this is intentional.'
        }

        if ([string]::IsNullOrWhiteSpace($TorrentId)) {
            throw 'DownloadToken requires -TorrentId.'
        }

        $endpoint = '/api/torrent/genDlToken'
        $uri = (Join-ApiUri $BaseUrl $endpoint) + '?id=' + [Uri]::EscapeDataString($TorrentId)
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers
        Write-ProbeOutput -Response $response -Endpoint "${endpoint}?id=<torrent id>" -Method 'POST'
    }
}

