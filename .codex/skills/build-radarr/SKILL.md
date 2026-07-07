---
name: build-radarr
description: Build or run Radarr from the arr-fork workspace using the verified local Windows workflow. Use when the user asks to compile, build, rebuild, run the compiled build, stop the compiled build, or verify Radarr locally, especially from F:\arr-fork\Radarr.
---

# Build Radarr

Use this workflow when compiling Radarr in this workspace. It captures the real local run from 2026-07-03 and avoids the setup mistakes already encountered.

## Preconditions

Work from `F:\arr-fork\Radarr`.

Confirm:

```powershell
dotnet --version
$env:COREPACK_ENABLE_AUTO_PIN='0'; corepack yarn --version
```

Expected:

- `.NET SDK` resolves to `8.0.421` because `global.json` pins it.
- Yarn resolves to `1.22.19` through Corepack.

If `.NET SDK 8.0.421` is missing, install it before building. On this machine, `winget install --id Microsoft.DotNet.SDK.8 --version 8.0.421 -e --accept-package-agreements --accept-source-agreements` worked after approval.

Do not use plain `yarn` unless it is on PATH. Prefer `corepack yarn`.

Always set `COREPACK_ENABLE_AUTO_PIN=0` when invoking Corepack in this repo, otherwise Corepack may append a `packageManager` field to `package.json`. If that happens, remove only that auto-added field and restore the repo to a clean state.

## Frontend Dependencies

Install dependencies before the frontend build:

```powershell
$env:COREPACK_ENABLE_AUTO_PIN='0'
corepack yarn install --frozen-lockfile --network-timeout 120000
```

Peer dependency warnings are expected and were non-fatal in the verified run.

## Backend Build

For a local Windows compile, limit the runtime to `win-x64` instead of building every RID. This is much faster and was the successful path.

```powershell
Remove-Item -Recurse -Force -LiteralPath _output,_tests -ErrorAction SilentlyContinue
dotnet clean src/Radarr.sln -c Debug
dotnet clean src/Radarr.sln -c Release
dotnet msbuild -restore src/Radarr.sln -p:SelfContained=True -p:Configuration=Release -p:Platform=Windows -p:RuntimeIdentifiers=win-x64 -t:PublishAllRids
```

Successful backend output includes:

```text
F:\arr-fork\Radarr\_output\net8.0-windows\win-x64\publish\Radarr.exe
```

Known non-fatal messages:

- `The Sentry CLI is not fully configured with authentication, organization, and project.`
- A transient `ffprobe.exe` copy retry warning can occur if another process briefly holds the file.

## Frontend Build

Run the production UI build:

```powershell
$env:COREPACK_ENABLE_AUTO_PIN='0'
corepack yarn run build --env production
```

Successful frontend output includes:

```text
F:\arr-fork\Radarr\_output\UI\index.html
```

Browserslist/caniuse-lite outdated notices are expected and were non-fatal in the verified run.

## Running The Compiled Build

The user's machine may already have a stable installed Radarr running. Before starting a compiled workspace build, find and stop any existing Radarr process so the compiled build owns the port and profile during testing.

Use process path inspection, not just process name, to distinguish stable installs from workspace builds:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'Radarr.exe' OR Name = 'Radarr.Console.exe'" |
  Select-Object ProcessId, Name, ExecutablePath, CommandLine
```

Before killing the stable process, record the stable executable path, command line, and whether it appears to be service-managed. Then stop/kill the existing process:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'Radarr.exe' OR Name = 'Radarr.Console.exe'" |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

Start the compiled build from the workspace output or refreshed artifact folder. Prefer the artifact folder if it was just synchronized for local testing:

```powershell
Start-Process -WindowStyle Hidden -FilePath (Resolve-Path -LiteralPath _artifacts\win-x64\net8.0\Radarr\Radarr.Console.exe).Path
```

If the artifact console executable does not exist, start the publish console executable instead:

```powershell
Start-Process -WindowStyle Hidden -FilePath (Resolve-Path -LiteralPath _output\net8.0\win-x64\publish\Radarr.Console.exe).Path
```

## Stopping The Compiled Build And Restoring Stable

When the user asks to end the compiled Radarr run, first inspect the running process path. Only stop the process if it is clearly running from this workspace, such as under `F:\arr-fork\Radarr\_output\` or `F:\arr-fork\Radarr\_artifacts\`.

```powershell
$workspace = (Resolve-Path -LiteralPath '.').Path
Get-CimInstance Win32_Process -Filter "Name = 'Radarr.exe' OR Name = 'Radarr.Console.exe'" |
  Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase) } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

Restart the stable installed Radarr using the executable path or service identity recorded before the compiled build was started. If no stable path was recorded, discover candidates from existing services and installed locations, but ask the user before starting anything when there is more than one plausible candidate.

## Windows Installer

Use this only after the backend and frontend outputs exist. The Bash `build.sh --packages --installer` path is not directly usable on this machine because `bash` was not available, so mirror the script in PowerShell.

Create the package input folder:

```powershell
$root = (Resolve-Path -LiteralPath '.').Path
$folder = Join-Path $root '_artifacts\win-x64\net8.0\Radarr'
$resolvedParent = Split-Path -Parent $folder
New-Item -ItemType Directory -Force -Path $resolvedParent | Out-Null
$fullFolder = [System.IO.Path]::GetFullPath($folder)
if (-not $fullFolder.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to write outside workspace: $fullFolder" }
Remove-Item -Recurse -Force -LiteralPath $fullFolder -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $fullFolder | Out-Null
Copy-Item -Recurse -Force -Path '_output\net8.0\win-x64\publish\*' -Destination $fullFolder
Copy-Item -Recurse -Force -LiteralPath '_output\Radarr.Update\net8.0\win-x64\publish' -Destination (Join-Path $fullFolder 'Radarr.Update')
Copy-Item -Recurse -Force -LiteralPath '_output\UI' -Destination (Join-Path $fullFolder 'UI')
Copy-Item -Force -LiteralPath 'LICENSE' -Destination $fullFolder
Copy-Item -Recurse -Force -Path '_output\net8.0-windows\win-x64\publish\*' -Destination $fullFolder
Remove-Item -Force -Path (Join-Path $fullFolder 'Radarr.Mono.*') -ErrorAction SilentlyContinue
Remove-Item -Force -Path (Join-Path $fullFolder 'Mono.Posix.NETStandard.*') -ErrorAction SilentlyContinue
Remove-Item -Force -Path (Join-Path $fullFolder 'libMonoPosixHelper.*') -ErrorAction SilentlyContinue
Copy-Item -Force -Path (Join-Path $fullFolder 'Radarr.Windows.*') -Destination (Join-Path $fullFolder 'Radarr.Update')
```

Install or locate Inno Setup `ISCC.exe`. CI uses Inno Setup `6.7.1`. On this machine, running the upstream installer with `//portable=1` still placed `ISCC.exe` at:

```text
C:\Program Files (x86)\Inno Setup 6\ISCC.exe
```

Compile the installer. Use native `/D...` arguments in PowerShell; `//D...` failed with `Unknown option`.

```powershell
$env:MAJORVERSION='6.2.2'
$env:MINORVERSION='0'
$env:RADARRVERSION='6.2.2.0'
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' distribution/windows/setup/radarr.iss '/DFramework=net8.0' '/DRuntime=win-x64'
```

Successful installer output from the verified run:

```text
F:\arr-fork\Radarr\distribution\windows\setup\output\Radarr.6.2.2.0.win-x64.exe
```

Expected non-fatal Inno warnings:

- `[UninstallRun] section entries without a RunOnceId parameter`
- `PrivilegesRequired` admin warning with `userstartup`
- `Variable 'Result' never used`

## Final Checks

Verify outputs and repository status:

```powershell
Test-Path -LiteralPath _output/net8.0-windows/win-x64/publish/Radarr.exe
Test-Path -LiteralPath _output/UI/index.html
Test-Path -LiteralPath distribution/windows/setup/output/Radarr.6.2.2.0.win-x64.exe
git status --short --branch
```

Report Git status separately:

- Radarr repository should be clean unless the user had pre-existing changes.
- Workspace root may change only if status or documentation files were intentionally updated.

Do not claim tests were run. This workflow builds and publishes test assemblies but does not execute the test suite.
