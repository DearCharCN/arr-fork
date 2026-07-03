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

    $branch = git -C $repoPath branch --show-current
    Write-Host "Branch: $branch"

    git -C $repoPath status --short
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
