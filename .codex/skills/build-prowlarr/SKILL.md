---
name: build-prowlarr
description: Build Prowlarr from the arr-fork workspace using the verified local Windows workflow. Use when the user asks to compile, build, rebuild, package, or create a Windows installer for Prowlarr.
---

# Build Prowlarr

Use this workflow when compiling Prowlarr in this workspace. It captures the real local run from 2026-07-03 and avoids the setup mistakes already encountered.

## Location

Work from:

```text
G:\arr-fork\Prowlarr
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
G:\arr-fork\Prowlarr\_output\net8.0-windows\win-x64\publish\Prowlarr.exe
G:\arr-fork\Prowlarr\_output\net8.0\win-x64\publish\Prowlarr.Console.exe
G:\arr-fork\Prowlarr\_output\Prowlarr.Update\net8.0\win-x64\publish\Prowlarr.Update.exe
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
G:\arr-fork\Prowlarr\_output\UI\index.html
```

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
G:\arr-fork\Prowlarr\distribution\windows\setup\output\Prowlarr.2.5.0.5422.win-x64.exe
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
Test-Path -LiteralPath distribution/windows/setup/output/Prowlarr.2.5.0.5422.win-x64.exe
Get-FileHash -Algorithm SHA256 -LiteralPath distribution/windows/setup/output/Prowlarr.2.5.0.5422.win-x64.exe
git status --short --branch
```

Report Git status separately:

- Prowlarr repository branch should be whatever the user asked to build.
- Generated installer output appears under `distribution/windows/setup/output/`.
- Workspace root may change only if status or documentation files were intentionally updated.

Do not claim tests were run. This workflow builds and publishes test assemblies but does not execute the test suite.
