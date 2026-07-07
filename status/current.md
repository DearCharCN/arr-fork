# Current AI Status

Last Updated: 2026-07-08

## Active Requirement

R005 - Custom Filter 支持嵌套条件组.

## Current Goal

Implement nested Custom Filter AND/OR condition groups in Prowlarr and Radarr. Sonarr is intentionally deferred per user request.

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
- [x] Implement Radarr R001 downstream support for Prowlarr Torznab/Newznab `audio`, `subs`, and media-info search state/progress attributes in release parsing, release API output, interactive search display, and automatic search waiting.
- [x] Rework Prowlarr M-Team MediaInfo enrichment so initial search results return immediately and audio/subtitle metadata is filled row-by-row.
- [x] Refine Prowlarr R001 search-result UI alignment, audio/subtitle manual sorting, and MediaInfo enrichment progress display.
- [x] Add Custom Filter support for audio/subtitle search-result fields and backend-tracked MediaInfo search progress fields for API/Torznab/Newznab consumers.
- [x] Record R005 draft requirement for nested Custom Filter condition groups across Prowlarr, Sonarr, and Radarr.
- [x] Implement R005 nested Custom Filter condition-group editing and client-side evaluation in Prowlarr and Radarr.

## Repository Status

### Prowlarr

Branch: my-feature, created from latest tag `v2.5.0.5422`.
Changes: R001 source changes in M-Team parsing, release/search models, Newznab output, search UI columns, localization, and M-Team parser fixtures; M-Team parser now handles real `mediainfo` text, preserves Atmos in audio specifications, displays compact multi-audio/multi-subtitle labels with popover details in desktop/mobile search results, and no longer blocks initial search on uncached `/api/torrent/mediaInfo` calls. Search results mark uncached M-Team rows as pending, `POST /api/v1/search/mediaInfo` enriches one cached release at a time, the frontend runs a small per-row enrichment queue, and audio/subtitle cells show reused spinner loading indicators until each row returns. Audio/subtitle table headers now share row-cell widths, those columns are manually sortable and filterable through Custom Filters, pending or empty media-info rows sort last, returned MediaInfo does not automatically refresh an existing media sort until the user sorts again, and the footer shows backend-reported MediaInfo enrichment progress plus completion. API and Torznab/Newznab release data now expose `mediaInfoSearchId`, `mediaInfoProgressStatus`, `mediaInfoProgressCompleted`, and `mediaInfoProgressTotal` so downstream consumers can see whether the result set is completed or still pending with progress. Torznab/Newznab downstream searches now cache their returned releases in the same MediaInfo cache used by Prowlarr's own search UI, allowing Radarr follow-up enrichment requests to resolve the original release instead of returning `404`. Successful MediaInfo responses remain cached for 7 days by torrent id and follow-up requests keep the explicit M-Team rate limit. R005 frontend changes add nested Custom Filter condition groups with per-group `and`/`or`, recursive client-side evaluation, legacy flat-AND serialization for simple filters, and grouped editor UI. Follow-up R005 fixes make group-header add buttons append conditions/groups inside the current group, make MediaInfo row updates refresh the full release list so rows that newly pass the active filter appear, and add Prowlarr Additional Data custom filtering.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer; backend `win-x64` publish and frontend production webpack were re-run after the compact media-display and Atmos parser update and passed. Backend `win-x64` publish was re-run after the full-page cached MediaInfo enrichment performance fix and passed. On 2026-07-04, frontend production webpack and backend `win-x64` publish were re-run after the row-by-row MediaInfo enrichment change and passed; installer generation was intentionally skipped. On 2026-07-07, frontend production webpack was re-run after the alignment/sort/progress UI update and passed, then backend `win-x64` publish, frontend production webpack, package folder assembly, and Windows installer generation were re-run successfully. Backend `win-x64` publish and frontend production webpack were re-run again after the Custom Filter/backend progress fields update and passed; UI was copied into all direct-run output folders. Backend `win-x64` publish was re-run again after adding downstream Torznab/Newznab MediaInfo cache sharing and passed; the running Prowlarr publish instance was restarted from `_output/net8.0/win-x64/publish`. On 2026-07-07, frontend production webpack and targeted ESLint passed after the R005 nested Custom Filter UI/evaluator changes. Backend `win-x64` publish and frontend production webpack were re-run again after R005, UI was copied beside direct-run outputs, and the running Prowlarr process was replaced from `_output/net8.0/win-x64/publish`. Frontend production webpack passed again after the R005 group-action and filtered MediaInfo row-update fixes. Backend `win-x64` publish and frontend production webpack were re-run again on user request, UI was copied into direct-run output folders, and Prowlarr was restarted from `_output/net8.0/win-x64/publish` with `http://localhost:9696/` returning `200 text/html`.
Installer: Produced `Prowlarr.2.5.0.5422.win-x64.exe` under `Prowlarr/distribution/windows/setup/output/`.
Tests: Not run; latest backend publish compiled test assemblies, including the Atmos parser fixture and the pending/per-row MediaInfo enrichment fixtures, but did not execute the test suite because test execution commands are still undocumented.

### Sonarr

Branch: my-feature, created from latest tag `v4.0.19.2979`.
Changes: Generated build output under `_output/`, `_tests/`, `_artifacts/`, and frontend dependencies under `node_modules/`; workspace docs updated with verified Sonarr build workflow.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer.
Installer: Produced `Sonarr.my-feature.4.0.19.2979.win-x64-installer.exe` under `Sonarr/_artifacts/`.
Tests: Not run; build generated test publish outputs but did not execute tests.

### Radarr

Branch: my-feature
Changes: R001 source changes in RSS release parsing, release models, release API resources, interactive search typings/table display, dedicated Audio Info/Subtitle Languages columns, header-level media-info progress display, stable media-field sort snapshots, Radarr-to-Prowlarr per-row MediaInfo proxying, automatic search active enrichment before pending media-info decisions, and a Torznab parser fixture for `audio`/`subs` plus media-info progress attributes; generated build output under `_output/`, `_tests/`, and refreshed frontend dependencies under `node_modules/`. Interactive Search no longer uses a separate Additional Data table column because the result-set progress is shown above the table; row audio/subtitle cells use compact labels with hover popovers and stop showing their loading indicator once that cell has data. R005 frontend changes add nested Custom Filter condition groups with per-group `and`/`or`, recursive client-side evaluation, legacy flat-AND serialization for simple filters, and grouped editor UI. Follow-up R005 fixes make group-header add buttons append conditions/groups inside the current group and make MediaInfo row updates refresh the full release list so rows that newly pass the active filter appear.
Build: Passed on 2026-07-03 for backend `win-x64`, frontend production webpack, and Windows installer. Backend `win-x64` publish and frontend production webpack were re-run after the R001 downstream media-field update and passed. On 2026-07-07, frontend production webpack and backend `win-x64` publish were re-run after the media-info progress/waiting update and passed, then re-run again after splitting Radarr interactive search media info into dedicated columns and passed. They were re-run again after replacing passive `/release` polling with the active `/release/mediaInfo` proxy path and automatic-search enrichment; the running local Radarr instance was synchronized from `_output` into `Radarr/_artifacts/win-x64/net8.0/Radarr` and restarted so the active UI/API contain the latest audio/subtitle/additional-data behavior. Frontend production webpack was re-run again after removing the Additional Data column and compacting audio/subtitle cells, then `_output/UI` was copied into the running `_artifacts/win-x64/net8.0/Radarr/UI` folder. On 2026-07-07, frontend production webpack and targeted ESLint passed after the R005 nested Custom Filter UI/evaluator changes. Backend `win-x64` publish and frontend production webpack were re-run again after R005, `_output` was synchronized into the running `_artifacts/win-x64/net8.0/Radarr` folder, and the running Radarr process was replaced from that folder. Frontend production webpack passed again after the R005 group-action and filtered MediaInfo row-update fixes. Backend `win-x64` publish and frontend production webpack were re-run again on user request; the installed Radarr process at `C:\ProgramData\Radarr\bin\Radarr.Console.exe` was left untouched.
Installer: Produced `Radarr.6.2.2.0.win-x64.exe` under `Radarr/distribution/windows/setup/output/`.
Tests: Not run; latest backend publish compiled test assemblies, including the new Torznab media-attribute fixture, but did not execute the test suite because test execution commands are still undocumented for this workspace.

## Next Steps

- Decide whether R001 should add downstream Sonarr parsing for the new `audio` and `subs` Torznab attributes before starting R002.
- Validate the row-by-row `/api/torrent/mediaInfo` enrichment path in the running compiled Prowlarr instance against real M-Team search results, confirming search results appear first, audio/subtitle cells update individually, progress reaches completion, and manual audio/subtitle sorting treats pending or empty rows as last.
- Re-open Radarr interactive search against real M-Team results, confirming the newly restarted Prowlarr instance lets Radarr per-row enrichment move progress beyond `0/61`, fills audio/subtitle rows individually, and does not automatically reorder MediaInfo-sorted rows until the user sorts again.
- Optionally run the full backend publish builds later if R005 expands beyond frontend/client-side filtering; current R005 changes only touched frontend code.
- Manually validate R005 in the running Prowlarr and Radarr UI by creating filters for `(条件1 or 条件2) and (条件3 or 条件4)` and `(条件1 and 条件2) or 条件3`.
- Run and document Sonarr build later with the user.
- Run and document debug, test, and release steps later with the user.

## Blockers

- Real M-Team `/api/torrent/search` responses only exposed summary fields such as `audioCodec`, `videoCodec`, and `hasChineseSubtitle`; full per-track audio/subtitle data was observed under `/api/torrent/detail` as `mediainfo` and under `/api/torrent/mediaInfo` as direct `data` text.
- `/api/torrent/mediaInfo` has no published separate quota. Live probes showed HTTP 200 + `請求過於頻繁` + empty `data` for rate limiting, fixed small intervals down to 1 second can work for limited batches, zero-delay burst thresholds are stateful and inconsistent, and recovery can exceed 10 minutes after stronger/repeated limit events. Follow-up enrichment should cache successful responses, stay single-concurrency, and use long backoff after rate-limit messages.
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
