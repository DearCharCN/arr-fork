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

    if (Test-Path $repoPath) {
        Write-Host "Directory already exists: $repoPath"
    }
    else {
        Write-Host "Cloning $($repo.url) into $repoPath"
        git clone $repo.url $repoPath
    }

    $gitDir = Join-Path $repoPath ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Warning "$repoPath is not a Git repository. Skipping remote setup."
        continue
    }

    $remoteNames = git -C $repoPath remote

    if ($repo.upstream -and ($remoteNames -notcontains "upstream")) {
        Write-Host "Adding upstream remote: $($repo.upstream)"
        git -C $repoPath remote add upstream $repo.upstream
    }
    elseif ($repo.upstream) {
        Write-Host "Upstream remote already exists."
    }

    if ($repo.defaultBranch) {
        Write-Host "Default branch: $($repo.defaultBranch)"
    }
}

Write-Host ""
Write-Host "Workspace setup complete." -ForegroundColor Green
