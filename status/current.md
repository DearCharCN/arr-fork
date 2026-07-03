# Current AI Status

Last Updated: 2026-07-03

## Active Requirement

R001 - Prowlarr M-Team 搜索结果增强媒体语言信息.

## Current Goal

Implement and validate the Prowlarr side of R001, then confirm the exact M-Team API media-info shape with a real response.

## Progress

- [x] Create root `.gitignore`.
- [x] Create workspace `README.md`.
- [x] Create `repos.json`.
- [x] Create workspace setup and status scripts.
- [x] Create AI navigation and planning structure.
- [x] Add first real requirement.
- [ ] Document debug, test, and release after running them with the user.
- [x] Document Radarr build after a real local run.
- [x] Add a project skill for repeating the Radarr build workflow.
- [x] Add a project skill for repeating the Prowlarr build and installer workflow.
- [x] Implement initial Prowlarr R001 support for M-Team audio languages, subtitle languages, and per-language audio specifications.
- [x] Document M-Team API access notes and add `.codex/skills/mteam-api/` for safe real-environment probes.
- [x] Validate M-Team search/detail media field shape against real API responses and adjust parser mapping for the observed `mediainfo` field.
- [x] Decide and implement the R001 media-info fetch strategy, because `/api/torrent/search` does not include full per-track audio/subtitle metadata and `/api/torrent/mediaInfo` can return the needed text directly.

## Repository Status

### Prowlarr

Branch: my-feature, created from latest tag `v2.5.0.5422`.
Changes: R001 source changes in M-Team parsing, release/search models, Newznab output, search UI columns, localization, and M-Team parser fixtures; M-Team parser now handles real `mediainfo` text, fetches `/api/torrent/mediaInfo` by torrent id when search results lack parseable track metadata, preserves Atmos in audio specifications, and displays compact multi-audio/multi-subtitle labels with popover details in desktop/mobile search results; generated installer output remains under `distribution/windows/setup/output/`.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer; backend `win-x64` publish and frontend production webpack were re-run after the compact media-display and Atmos parser update and passed. The latest user-requested compile intentionally skipped installer generation.
Installer: Produced `Prowlarr.2.5.0.5422.win-x64.exe` under `Prowlarr/distribution/windows/setup/output/`.
Tests: Not run; latest backend publish compiled test assemblies, including the Atmos parser fixture, but did not execute the test suite.

### Sonarr

Branch: my-feature, created from latest tag `v4.0.19.2979`.
Changes: Generated build output under `_output/`, `_tests/`, `_artifacts/`, and frontend dependencies under `node_modules/`; workspace docs updated with verified Sonarr build workflow.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer.
Installer: Produced `Sonarr.my-feature.4.0.19.2979.win-x64-installer.exe` under `Sonarr/_artifacts/`.
Tests: Not run; build generated test publish outputs but did not execute tests.

### Radarr

Branch: my-feature
Changes: Clean after local build.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer.
Installer: Produced `Radarr.6.2.2.0.win-x64.exe` under `Radarr/distribution/windows/setup/output/`.
Tests: Not run; build generated test publish outputs but did not execute tests.

## Next Steps

- Decide whether R001 should add downstream Sonarr/Radarr parsing for the new `audio` Torznab attribute before starting R002.
- Validate the `/api/torrent/mediaInfo` enrichment path in a running Prowlarr instance against real M-Team search results.
- Run and document Sonarr build later with the user.
- Run and document debug, test, and release steps later with the user.

## Blockers

- Real M-Team `/api/torrent/search` responses only exposed summary fields such as `audioCodec`, `videoCodec`, and `hasChineseSubtitle`; full per-track audio/subtitle data was observed under `/api/torrent/detail` as `mediainfo` and under `/api/torrent/mediaInfo` as direct `data` text.
- `/api/torrent/mediaInfo` has no published separate quota; the parser skips remaining mediaInfo enrichment after a 429 response, but real search latency and quota behavior still need running-instance validation.
- Test execution commands are still undocumented; only build verification has been run.

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
- Prowlarr SDK note: when system .NET SDK `8.0.421` was unavailable, installed the official SDK into workspace-local `F:\arr-fork\.dotnet` and used `F:\arr-fork\.dotnet\dotnet.exe` for backend compilation; `.dotnet/` is ignored by the workspace root Git repository.
- Confirmed Prowlarr frontend build command from `Prowlarr/`: `corepack yarn install --frozen-lockfile --network-timeout 120000`, then `corepack yarn run build --env production`, with `COREPACK_ENABLE_AUTO_PIN=0`.
- Confirmed Prowlarr installer generation with Inno Setup `6.7.1`; PowerShell invocation uses `/DFramework=net8.0` and `/DRuntime=win-x64`, with `MAJORVERSION=2.5.0`, `MINORVERSION=5422`, and `PROWLARRVERSION=2.5.0.5422`.
- Project skill `.codex/skills/build-prowlarr/SKILL.md` records the repeatable Prowlarr build, NuGet v2 restore workaround, and installer workflow. It intentionally does not include branch creation as a required build step.
- Confirmed Sonarr latest tag on 2026-07-03 after fetching upstream tags: `v4.0.19.2979`; created `my-feature` from that tag.
- Confirmed Sonarr local build prerequisites: .NET SDK `6.0.428` satisfies `global.json` version `6.0.405`, Node `v22.12.0`, and Yarn through Corepack.
- Confirmed Sonarr backend build command from `Sonarr/`: `dotnet clean src/Sonarr.sln -c Debug`; `dotnet clean src/Sonarr.sln -c Release`; then `dotnet msbuild -restore src/Sonarr.sln -p:Configuration=Release -p:Platform=Windows -p:RuntimeIdentifiers=win-x64 -p:AssemblyVersion=4.0.19.2979 -p:AssemblyConfiguration=my-feature -t:PublishAllRids`.
- Confirmed Sonarr frontend build command from `Sonarr/`: `corepack yarn install --frozen-lockfile --network-timeout 120000`, then `corepack yarn run build --env production`, with `COREPACK_ENABLE_AUTO_PIN=0`.
- Confirmed Sonarr installer generation with bundled Inno Setup 5 under `Sonarr/distribution/windows/setup/inno/ISCC.exe`; installer input must be prepared at `_output/win-x64/net6.0/Sonarr`, and environment variables were `SONARR_MAJOR_VERSION=4.0.19`, `SONARR_VERSION=4.0.19.2979`, `BRANCH=my-feature`, `FRAMEWORK=net6.0`, and `RUNTIME=win-x64`.
- Project skill `.codex/skills/build-sonarr/SKILL.md` records the repeatable Sonarr build and installer workflow plus Corepack/package.json pitfall.
