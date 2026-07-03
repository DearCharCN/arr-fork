# Current AI Status

Last Updated: 2026-07-03

## Active Requirement

None.

## Current Goal

Prepare the workspace structure for AI-assisted cross-repository development.

## Progress

- [x] Create root `.gitignore`.
- [x] Create workspace `README.md`.
- [x] Create `repos.json`.
- [x] Create workspace setup and status scripts.
- [x] Create AI navigation and planning structure.
- [ ] Add first real requirement.
- [ ] Document debug, test, and release after running them with the user.
- [x] Document Radarr build after a real local run.
- [x] Add a project skill for repeating the Radarr build workflow.
- [x] Add a project skill for repeating the Prowlarr build and installer workflow.

## Repository Status

### Prowlarr

Branch: my-feature, created from latest tag `v2.5.0.5422`.
Changes: Only generated installer output under `distribution/windows/setup/output/`.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer.
Installer: Produced `Prowlarr.2.5.0.5422.win-x64.exe` under `Prowlarr/distribution/windows/setup/output/`.
Tests: Not run; build generated test publish outputs but did not execute tests.

### Sonarr

Branch: v5-develop
Changes: Not checked in this status file.
Tests: Not run.

### Radarr

Branch: my-feature
Changes: Clean after local build.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer.
Installer: Produced `Radarr.6.2.2.0.win-x64.exe` under `Radarr/distribution/windows/setup/output/`.
Tests: Not run; build generated test publish outputs but did not execute tests.

## Next Steps

- Add the first requirement to `planning/requirements.md`.
- Explore relevant code paths once a requirement is selected.
- Run and document Sonarr build later with the user.
- Run and document debug, test, and release steps later with the user.

## Blockers

- No active feature requirement has been selected yet.

## Notes For Next AI Session

- Start with `INDEX.md` and `AGENTS.md`.
- Do not invent build, debug, test, or release commands.
- Confirmed Radarr local build prerequisites: .NET SDK `8.0.421`, Node available, and Yarn `1.22.19` via `corepack yarn`.
- Confirmed Radarr backend build command from `Radarr/`: `dotnet clean src/Radarr.sln -c Debug`; `dotnet clean src/Radarr.sln -c Release`; `dotnet msbuild -restore src/Radarr.sln -p:SelfContained=True -p:Configuration=Release -p:Platform=Windows -p:RuntimeIdentifiers=win-x64 -t:PublishAllRids`.
- Confirmed Radarr frontend build command from `Radarr/`: `corepack yarn install --frozen-lockfile --network-timeout 120000`, then `corepack yarn run build --env production`.
- Confirmed Radarr installer generation with Inno Setup `6.7.1`; PowerShell invocation needs `/DFramework=net8.0` and `/DRuntime=win-x64`.
- Project skill `.codex/skills/build-radarr/SKILL.md` records the repeatable Radarr build and installer workflow plus Corepack/package.json pitfall.
- Confirmed Prowlarr latest tag on 2026-07-03: `v2.5.0.5422`; created `my-feature` from that tag.
- Confirmed Prowlarr backend build command from `Prowlarr/`: `dotnet clean src/Prowlarr.sln -c Debug`; `dotnet clean src/Prowlarr.sln -c Release`; then `dotnet msbuild -restore src/Prowlarr.sln -p:RestoreSources=https://www.nuget.org/api/v2/ -p:NuGetAudit=false -p:SelfContained=True -p:Configuration=Release -p:Platform=Windows -p:RuntimeIdentifiers=win-x64 -p:AssemblyVersion=2.5.0.5422 -p:AssemblyConfiguration=my-feature -t:PublishAllRids`.
- Prowlarr build note: `https://api.nuget.org/v3/index.json` failed locally with TLS principal mismatch; official v2 source `https://www.nuget.org/api/v2/` worked.
- Confirmed Prowlarr frontend build command from `Prowlarr/`: `corepack yarn install --frozen-lockfile --network-timeout 120000`, then `corepack yarn run build --env production`, with `COREPACK_ENABLE_AUTO_PIN=0`.
- Confirmed Prowlarr installer generation with Inno Setup `6.7.1`; PowerShell invocation uses `/DFramework=net8.0` and `/DRuntime=win-x64`, with `MAJORVERSION=2.5.0`, `MINORVERSION=5422`, and `PROWLARRVERSION=2.5.0.5422`.
- Project skill `.codex/skills/build-prowlarr/SKILL.md` records the repeatable Prowlarr build, NuGet v2 restore workaround, and installer workflow. It intentionally does not include branch creation as a required build step.
