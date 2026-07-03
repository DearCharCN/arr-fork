$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$reposFile = Join-Path $workspaceRoot "repos.json"

if (-not (Test-Path $reposFile)) {
    throw "Cannot find repos.json at $reposFile"
}

$config = Get-Content $reposFile -Raw | ConvertFrom-Json

foreach ($repo in $config.repositories) {
    $repoPath = Join-Path $workspaceRoot $repo.path

    Write-Host ""
    Write-Host "==> $($repo.name)" -ForegroundColor Cyan

    if (-not (Test-Path $repoPath)) {
        Write-Warning "Missing directory: $repoPath"
        continue
    }

    $gitDir = Join-Path $repoPath ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Warning "Not a Git repository: $repoPath"
        continue
    }

    git -C $repoPath fetch --all --prune
}

Write-Host ""
Write-Host "Sync complete." -ForegroundColor Green
