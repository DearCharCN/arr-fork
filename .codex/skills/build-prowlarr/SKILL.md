---
name: build-prowlarr
description: Build or run Prowlarr from the arr-fork workspace using the verified local Windows workflow. Use when the user asks to compile, build, rebuild, package, run the compiled build, stop the compiled build, or create a Windows installer for Prowlarr.
---

# Build Prowlarr

Use this workflow when compiling Prowlarr in this workspace. It captures the real local run from 2026-07-03 and avoids the setup mistakes already encountered.

## Location

Work from:

```text
F:\arr-fork\Prowlarr
```

## Preconditions

Confirm:

```powershell
dotnet --version
$env:COREPACK_ENABLE_AUTO_PIN='0'; corepack yarn --version
node --version
Get-Command 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' -ErrorAction SilentlyContinue
```

Expected:

- `.NET SDK` resolves to `8.0.421` because `global.json` pins it.
- Yarn resolves to `1.22.19` through Corepack.
- Inno Setup `ISCC.exe` is available. CI uses Inno Setup `6.7.1`.

Always set `COREPACK_ENABLE_AUTO_PIN=0` when invoking Corepack in this repo, otherwise Corepack may append a `packageManager` field to `package.json`.

## Frontend Dependencies

Install dependencies:

```powershell
$env:COREPACK_ENABLE_AUTO_PIN='0'
corepack yarn install --frozen-lockfile --network-timeout 120000
```

Known non-fatal dependency messages:

- `chart.js@4.4.4: The engine "pnpm" appears to be invalid.`
- React peer dependency warnings from older packages.
- Node `punycode` deprecation warning.

## Backend Build

For a local Windows compile, limit the runtime to `win-x64` instead of building every RID.

Important local NuGet note: `https://api.nuget.org/v3/index.json` failed on this machine with a TLS principal mismatch. Use official NuGet v2 as the restore source and disable audit network checks:

```powershell
Remove-Item -Recurse -Force -LiteralPath _output,_tests -ErrorAction SilentlyContinue
dotnet clean src/Prowlarr.sln -c Debug
dotnet clean src/Prowlarr.sln -c Release
dotnet msbuild -restore src/Prowlarr.sln -p:RestoreSources=https://www.nuget.org/api/v2/ -p:NuGetAudit=false -p:SelfContained=True -p:Configuration=Release -p:Platform=Windows -p:RuntimeIdentifiers=win-x64 -p:AssemblyVersion=2.5.0.5422 -p:AssemblyConfiguration=my-feature -t:PublishAllRids
```

For another checked-out version, derive:

- `AssemblyVersion` from the checked-out tag when building a tag, without leading `v`; otherwise use the intended local version.
- `AssemblyConfiguration` from the current branch name.

Successful backend output includes:

```text
F:\arr-fork\Prowlarr\_output\net8.0-windows\win-x64\publish\Prowlarr.exe
F:\arr-fork\Prowlarr\_output\net8.0\win-x64\publish\Prowlarr.Console.exe
F:\arr-fork\Prowlarr\_output\Prowlarr.Update\net8.0\win-x64\publish\Prowlarr.Update.exe
```

Known non-fatal message:

- `The Sentry CLI is not fully configured with authentication, organization, and project.`

## Frontend Build

Run the production UI build:

```powershell
$env:COREPACK_ENABLE_AUTO_PIN='0'
corepack yarn run build --env production
```

Successful frontend output includes:

```text
F:\arr-fork\Prowlarr\_output\UI\index.html
```

## Local Run UI Copy

When running `Prowlarr.Console.exe` or `Prowlarr.exe` directly from build output, copy the frontend output beside the executable first. The backend build leaves runnable executables in both non-publish and publish output folders; if `UI\login.html` is missing beside the executable, the web root returns a JSON 404.

```powershell
$root = (Resolve-Path -LiteralPath '.').Path
$source = Join-Path $root '_output\UI'
$destinations = @(
  '_output\net8.0\win-x64\UI',
  '_output\net8.0\win-x64\publish\UI',
  '_output\net8.0-windows\win-x64\UI',
  '_output\net8.0-windows\win-x64\publish\UI',
  '_artifacts\win-x64\net8.0\Prowlarr\UI'
)
foreach ($relativeDest in $destinations) {
  $dest = Join-Path $root $relativeDest
  $destFull = [System.IO.Path]::GetFullPath($dest)
  if (-not $destFull.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to copy outside repo: $destFull" }
  Remove-Item -Recurse -Force -LiteralPath $destFull -ErrorAction SilentlyContinue
  Copy-Item -Recurse -Force -LiteralPath $source -Destination $destFull
}
```

Use this after backend and frontend builds, before opening `http://localhost:9696/` from any direct output-folder run. If skipped, Prowlarr can start successfully but return a JSON 404 for `/` or `/index.html`, with log warnings like:

```text
LoginHtmlMapper|File ...\_output\net8.0\win-x64\publish\UI\login.html not found
```

Verify the local web UI:

```powershell
Test-Path -LiteralPath _output\net8.0\win-x64\UI\login.html
Test-Path -LiteralPath _output\net8.0\win-x64\publish\UI\login.html
Test-Path -LiteralPath _output\net8.0-windows\win-x64\UI\login.html
Test-Path -LiteralPath _output\net8.0-windows\win-x64\publish\UI\login.html
Test-Path -LiteralPath _artifacts\win-x64\net8.0\Prowlarr\UI\login.html
Invoke-WebRequest -Uri 'http://localhost:9696/' -UseBasicParsing -TimeoutSec 10
```

## Running The Compiled Build

The user's machine may already have a stable installed Prowlarr running. Before starting a compiled workspace build, find and stop any existing Prowlarr process so the compiled build owns the port and profile during testing.

Use process path inspection, not just process name, to distinguish stable installs from workspace builds:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'Prowlarr.exe' OR Name = 'Prowlarr.Console.exe'" |
  Select-Object ProcessId, Name, ExecutablePath, CommandLine
```

Before killing the stable process, record the stable executable path, command line, and whether it appears to be service-managed. Then stop/kill the existing process:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'Prowlarr.exe' OR Name = 'Prowlarr.Console.exe'" |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

Start the compiled build from the workspace output. Prefer the publish console executable after confirming the UI output exists beside it or is linked to `_output\UI`:

```powershell
Test-Path -LiteralPath _output\net8.0\win-x64\publish\UI\login.html
Start-Process -WindowStyle Hidden -FilePath (Resolve-Path -LiteralPath _output\net8.0\win-x64\publish\Prowlarr.Console.exe).Path
```

## Stopping The Compiled Build And Restoring Stable

When the user asks to end the compiled Prowlarr run, first inspect the running process path. Only stop the process if it is clearly running from this workspace, such as under `F:\arr-fork\Prowlarr\_output\` or `F:\arr-fork\Prowlarr\_artifacts\`.

```powershell
$workspace = (Resolve-Path -LiteralPath '.').Path
Get-CimInstance Win32_Process -Filter "Name = 'Prowlarr.exe' OR Name = 'Prowlarr.Console.exe'" |
  Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase) } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

Restart the stable installed Prowlarr using the executable path or service identity recorded before the compiled build was started. If no stable path was recorded, discover candidates from existing services and installed locations, but ask the user before starting anything when there is more than one plausible candidate.

## Windows Installer

Use this only after backend and frontend outputs exist. `build.sh --packages --installer` is Bash-oriented; on this machine, mirror the script in PowerShell.

Create the package input folder:

```powershell
$root = (Resolve-Path -LiteralPath '.').Path
$folder = Join-Path $root '_artifacts\win-x64\net8.0\Prowlarr'
$resolvedParent = Split-Path -Parent $folder
New-Item -ItemType Directory -Force -Path $resolvedParent | Out-Null
$fullFolder = [System.IO.Path]::GetFullPath($folder)
if (-not $fullFolder.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to write outside workspace: $fullFolder" }
Remove-Item -Recurse -Force -LiteralPath $fullFolder -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $fullFolder | Out-Null
Copy-Item -Recurse -Force -Path '_output\net8.0\win-x64\publish\*' -Destination $fullFolder
Copy-Item -Recurse -Force -LiteralPath '_output\Prowlarr.Update\net8.0\win-x64\publish' -Destination (Join-Path $fullFolder 'Prowlarr.Update')
Copy-Item -Recurse -Force -LiteralPath '_output\UI' -Destination (Join-Path $fullFolder 'UI')
Copy-Item -Force -LiteralPath 'LICENSE' -Destination $fullFolder
Copy-Item -Recurse -Force -Path '_output\net8.0-windows\win-x64\publish\*' -Destination $fullFolder
Remove-Item -Force -Path (Join-Path $fullFolder 'Prowlarr.Mono.*') -ErrorAction SilentlyContinue
Remove-Item -Force -Path (Join-Path $fullFolder 'Mono.Posix.NETStandard.*') -ErrorAction SilentlyContinue
Remove-Item -Force -Path (Join-Path $fullFolder 'libMonoPosixHelper.*') -ErrorAction SilentlyContinue
Copy-Item -Force -Path (Join-Path $fullFolder 'Prowlarr.Windows.*') -Destination (Join-Path $fullFolder 'Prowlarr.Update')
```

Compile the installer. Use native `/D...` arguments in PowerShell; `//D...` can fail with `Unknown option`.

```powershell
$env:MAJORVERSION='2.5.0'
$env:MINORVERSION='5422'
$env:PROWLARRVERSION='2.5.0.5422'
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' distribution/windows/setup/prowlarr.iss '/DFramework=net8.0' '/DRuntime=win-x64'
```

For a different tag, split `vA.B.C.D` into:

- `MAJORVERSION=A.B.C`
- `MINORVERSION=D`
- `PROWLARRVERSION=A.B.C.D`

Successful installer output from the verified run:

```text
F:\arr-fork\Prowlarr\distribution\windows\setup\output\Prowlarr.2.5.0.5422.win-x64.exe
```

Expected non-fatal Inno warnings:

- `[UninstallRun] section entries without a RunOnceId parameter`
- `PrivilegesRequired` admin warning with `userstartup`
- `Variable 'Result' never used`

## Final Checks

Verify outputs:

```powershell
Test-Path -LiteralPath _output/net8.0-windows/win-x64/publish/Prowlarr.exe
Test-Path -LiteralPath _output/net8.0/win-x64/publish/Prowlarr.Console.exe
Test-Path -LiteralPath _output/UI/index.html
Test-Path -LiteralPath _output/net8.0/win-x64/UI/login.html
Test-Path -LiteralPath _output/net8.0/win-x64/publish/UI/login.html
Test-Path -LiteralPath _output/net8.0-windows/win-x64/UI/login.html
Test-Path -LiteralPath _output/net8.0-windows/win-x64/publish/UI/login.html
Test-Path -LiteralPath _artifacts/win-x64/net8.0/Prowlarr/UI/login.html
Test-Path -LiteralPath distribution/windows/setup/output/Prowlarr.2.5.0.5422.win-x64.exe
Get-FileHash -Algorithm SHA256 -LiteralPath distribution/windows/setup/output/Prowlarr.2.5.0.5422.win-x64.exe
git status --short --branch
```

Report Git status separately:

- Prowlarr repository branch should be whatever the user asked to build.
- Generated installer output appears under `distribution/windows/setup/output/`.
- Workspace root may change only if status or documentation files were intentionally updated.

Do not claim tests were run. This workflow builds and publishes test assemblies but does not execute the test suite.
