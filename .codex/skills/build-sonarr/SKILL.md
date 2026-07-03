---
name: build-sonarr
description: Build Sonarr from the arr-fork workspace using the verified local Windows workflow. Use when the user asks to compile, build, rebuild, package, or create a Windows installer for Sonarr.
---

# Build Sonarr

Use this workflow when compiling Sonarr in this workspace. It captures the real local run from 2026-07-03.

## Location

Work from:

```text
F:\arr-fork\Sonarr
```

## Preconditions

Confirm:

```powershell
dotnet --version
node --version
$env:COREPACK_ENABLE_AUTO_PIN='0'; corepack yarn --version
Test-Path -LiteralPath distribution/windows/setup/inno/ISCC.exe
```

Expected on the verified machine:

- `.NET SDK` resolves to `6.0.428`, satisfying Sonarr's `global.json` request for `6.0.405`.
- Node was `v22.12.0`.
- Yarn resolved through Corepack; the verified run used `1.22.22`.
- Sonarr includes its own Inno Setup 5 compiler at `distribution/windows/setup/inno/ISCC.exe`.

If .NET 6 SDK is missing, install it before building. On this machine, `winget install --id Microsoft.DotNet.SDK.6 --exact --accept-package-agreements --accept-source-agreements --disable-interactivity` installed SDK `6.0.428` after approval.

Always set `COREPACK_ENABLE_AUTO_PIN=0` when invoking Corepack in this repo, otherwise Corepack may append a `packageManager` field to `package.json`. If that happens, remove only that auto-added field.

## Backend Build

For a local Windows compile, limit the runtime to `win-x64` instead of building every RID.

```powershell
dotnet clean src/Sonarr.sln -c Debug
dotnet clean src/Sonarr.sln -c Release
dotnet msbuild -restore src/Sonarr.sln -p:Configuration=Release -p:Platform=Windows -p:RuntimeIdentifiers=win-x64 -p:AssemblyVersion=4.0.19.2979 -p:AssemblyConfiguration=my-feature -t:PublishAllRids
```

For another checked-out version, derive:

- `AssemblyVersion` from the checked-out tag when building a tag, without leading `v`; otherwise use the intended local version.
- `AssemblyConfiguration` from the current branch name.

Successful backend output includes:

```text
F:\arr-fork\Sonarr\_output\net6.0-windows\win-x64\publish\Sonarr.exe
F:\arr-fork\Sonarr\_output\net6.0\win-x64\publish\Sonarr.Console.exe
F:\arr-fork\Sonarr\_output\Sonarr.Update\net6.0\win-x64\publish\Sonarr.Update.exe
```

Known non-fatal messages from the verified run:

- `The Sentry CLI is not fully configured with authentication, organization, and project.`
- A transient `Microsoft.CodeCoverage` copy retry warning can occur while publishing test assemblies.
- A Sentry API request warning can occur because release symbol upload is not configured locally.

## Frontend Build

Install dependencies and run the production UI build:

```powershell
$env:COREPACK_ENABLE_AUTO_PIN='0'
corepack yarn install --frozen-lockfile --network-timeout 120000
corepack yarn run build --env production
```

Peer dependency warnings, `string-width` cache warnings, and Browserslist/caniuse-lite outdated notices were non-fatal in the verified run.

Successful frontend output includes:

```text
F:\arr-fork\Sonarr\_output\UI\index.html
```

## Windows Installer

Use this only after backend and frontend outputs exist. The Bash `build.sh` path is not directly usable on this machine because `bash` was not available, so mirror the package step in PowerShell.

Sonarr's Inno script writes to `_artifacts`, but reads installer input from `_output\win-x64\net6.0\Sonarr`. Create that input folder:

```powershell
$root = (Resolve-Path '.').Path
$dest = Join-Path $root '_output\win-x64\net6.0\Sonarr'
if (-not $dest.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Destination outside workspace: $dest" }
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $root '_output\net6.0\win-x64\publish\*') -Destination $dest -Recurse -Force
New-Item -ItemType Directory -Force -Path (Join-Path $dest 'Sonarr.Update') | Out-Null
Copy-Item -Path (Join-Path $root '_output\Sonarr.Update\net6.0\win-x64\publish\*') -Destination (Join-Path $dest 'Sonarr.Update') -Recurse -Force
Copy-Item -Path (Join-Path $root '_output\UI') -Destination $dest -Recurse -Force
Copy-Item -Path (Join-Path $root 'LICENSE.md') -Destination $dest -Force
Copy-Item -Path (Join-Path $root '_output\net6.0-windows\win-x64\publish\*') -Destination $dest -Recurse -Force
Remove-Item -Path (Join-Path $dest 'Sonarr.Mono.*') -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $dest 'Mono.Posix.NETStandard.*') -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $dest 'libMonoPosixHelper.*') -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $dest 'Sonarr.Windows.*') -Destination (Join-Path $dest 'Sonarr.Update') -Force
```

Compile the installer:

```powershell
$env:SONARR_MAJOR_VERSION='4.0.19'
$env:SONARR_VERSION='4.0.19.2979'
$env:BRANCH='my-feature'
$env:FRAMEWORK='net6.0'
$env:RUNTIME='win-x64'
Push-Location distribution/windows/setup
.\inno\ISCC.exe sonarr.iss
Pop-Location
```

For a different tag `vA.B.C.D`, use:

- `SONARR_MAJOR_VERSION=A.B.C`
- `SONARR_VERSION=A.B.C.D`
- `BRANCH` as the current branch name

Successful installer output from the verified run:

```text
F:\arr-fork\Sonarr\_artifacts\Sonarr.my-feature.4.0.19.2979.win-x64-installer.exe
```

Expected non-fatal Inno warnings:

- `ISPPBuiltins.iss file was not found`
- `Variable 'Result' never used`

## Final Checks

Verify outputs:

```powershell
Test-Path -LiteralPath _output/net6.0-windows/win-x64/publish/Sonarr.exe
Test-Path -LiteralPath _output/net6.0/win-x64/publish/Sonarr.Console.exe
Test-Path -LiteralPath _output/UI/index.html
Test-Path -LiteralPath _artifacts/Sonarr.my-feature.4.0.19.2979.win-x64-installer.exe
Get-FileHash -Algorithm SHA256 -LiteralPath _artifacts/Sonarr.my-feature.4.0.19.2979.win-x64-installer.exe
git status --short --branch
```

Do not claim tests were run. This workflow builds and publishes test assemblies but does not execute the test suite.
