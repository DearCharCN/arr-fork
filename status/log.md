# AI Activity Log

Record chronological AI activity, command runs, setup steps, and status checks here when those details need to be preserved.

Project, requirement, and user-visible feature changes belong in `status/changelog.md` instead.

## 2026-07-03

- Created root workspace `.gitignore`.
- Created workspace `README.md`.
- Created `repos.json` for Prowlarr, Sonarr, and Radarr.
- Created `scripts/setup.ps1` for cloning missing source repositories.
- Created `scripts/status.ps1` for checking source repository status.
- Created AI-oriented workspace structure and navigation files.
- Ran and documented a real Radarr local build: installed .NET SDK 8.0.421, activated Yarn 1.22.19 through Corepack, built backend for `win-x64`, and built the frontend production UI.
- Added project skill `.codex/skills/build-radarr/` so future Radarr build requests can follow the verified workflow directly.
- Ran and documented Radarr Windows installer generation, producing `Radarr.6.2.2.0.win-x64.exe` with Inno Setup 6.7.1.
- Created Prowlarr `my-feature` from latest tag `v2.5.0.5422`, built backend and frontend, and produced `Prowlarr.2.5.0.5422.win-x64.exe` with Inno Setup 6.7.1.
- Added project skill `.codex/skills/build-prowlarr/` so future Prowlarr build and installer requests can follow the verified workflow directly.
- Initialized this local workspace by running `scripts/setup.ps1`; cloned Prowlarr, Sonarr, and Radarr, and configured each upstream remote.
- Reclassified `status/changelog.md` as a project requirement and feature changelog; moved previous AI activity entries into this log file.
- Corrected initialization mistakes: restored `status/current.md` as the target state file, switched Prowlarr to local `my-feature` from tag `v2.5.0.5422`, switched Radarr to `my-feature` tracking `origin/my-feature`, and updated AI guidance so future initialization follows `current` without modifying it.
- Fetched Sonarr upstream tags and created local `my-feature` from latest tag `v4.0.19.2979`.
- Installed .NET SDK 6.0.428 for Sonarr, built Sonarr backend for `win-x64`, built frontend production UI, prepared the Windows installer input folder, and produced `Sonarr.my-feature.4.0.19.2979.win-x64-installer.exe` with the bundled Inno Setup 5 compiler.
- Added project skill `.codex/skills/build-sonarr/` so future Sonarr build and installer requests can follow the verified workflow directly.
- Began R001 implementation, choosing Prowlarr first because M-Team media metadata is the upstream field source for later Sonarr/Radarr sorting work.
- Implemented initial Prowlarr R001 support: parsed flexible M-Team audio/subtitle media fields, added structured release audio info, exposed audio/subtitle metadata through the search API and Newznab/Torznab output, and added search UI columns.
- Added a M-Team parser fixture covering English TrueHD and Chinese DDP 5.1 audio specs plus subtitle languages; the fixture was compiled by the backend build but not executed.
- Re-ran the documented Prowlarr backend publish build for `win-x64`; it passed with the known non-fatal Sentry API warning.
- Re-ran the documented Prowlarr frontend production webpack build; the first run generated missing CSS module typings and failed on those typings, then the second run passed.
- Read M-Team API wiki at `https://wiki.m-team.cc/zh-tw/api`; documented token-based `x-api-key` access, Swagger caveats, disallowed prefixes, and published rate limits without storing the raw token.
- Added `guides/mteam-api.md` and `.codex/skills/mteam-api/` with a PowerShell probe script for sanitized M-Team profile/search/detail/download-token requests.
- Validated the `mteam-api` skill with `quick_validate.py` and checked the PowerShell probe script with the PowerShell parser; no live M-Team API request was run.
- Generalized the `mteam-api` skill wording so it applies to all M-Team related development and real-data testing, not only one requirement.
- Ran live M-Team API probes with sanitized output under `tmp/`: profile plus search samples for `Interstellar`, `Inception`, and `Dune`.
- Observed that real `/api/torrent/search` responses do not contain structured `mediaInfo.audio` or `mediaInfo.subtitles`; search results expose summary fields including `audioCodec`, `videoCodec`, and `hasChineseSubtitle`.
- Ran live `/api/torrent/detail` probes for selected search result ids and confirmed full per-track audio/subtitle data appears in the detail `mediainfo` text field, using BDInfo `AUDIO`/`SUBTITLES` tables or MediaInfo `Audio #`/`Text #` sections.
- Fixed a strict-mode endpoint-string bug in `.codex/skills/mteam-api/scripts/Invoke-MTeamApiProbe.ps1` that affected detail/download-token output labeling.
- Updated the M-Team parser and fixture to parse real `mediainfo` text shapes, then re-ran the documented Prowlarr backend publish build for `win-x64`; it passed with the known non-fatal Sentry API warning.
- Explored production frontend static JS for alternate M-Team media endpoints; found related endpoints including `/torrent/files`, `/subtitle/list`, `/subtitle/search`, `/torrent/audioCodecList`, `/tracker/queryHistory`, and alternate API host `api.m-team.io`.
- Probed alternate M-Team endpoints with sanitized captures under `tmp/mteam-alt-api/`; none returned the per-track audio/subtitle metadata available in `/torrent/detail`'s `mediainfo`.
- Confirmed after user pointed it out that `/api/torrent/mediaInfo` returns the MediaInfo text directly for one torrent via `POST ?id=<torrent id>` or form body `id=<torrent id>`; no rate/quota headers were visible, and the official wiki does not publish a separate quota for this endpoint.
- Changed the R001 M-Team parser to fetch `/api/torrent/mediaInfo` by torrent id when search results lack parseable track metadata, added a parser fixture for that fallback path, and recorded the strategy in `planning/decisions.md`.
- Re-ran the documented Prowlarr backend publish build for `win-x64`; it passed with the known non-fatal Sentry API warning. Test assemblies compiled, but the test suite was not executed because test commands are not yet documented for this workspace.
- Updated R001 per user feedback: desktop and mobile Prowlarr search results now show compact media labels for multi-audio and multi-subtitle results, with full details in popovers; M-Team audio specification parsing now preserves Atmos markers from MediaInfo/BDInfo.
- Ran `corepack yarn run build --env production` from `Prowlarr/`; the first run failed on a strict TypeScript string-array narrowing issue in the new media display component, then passed after adding an explicit type guard.
- Attempted the documented Prowlarr backend publish build, but it did not start because `Prowlarr/global.json` requires .NET SDK `8.0.421` and the machine currently lists only `6.0.428`, `8.0.407`, and `9.0.203`.
- Installed official .NET SDK `8.0.421` into workspace-local `F:\arr-fork\.dotnet` using `dotnet-install.ps1`, added `/.dotnet/` to the root `.gitignore`, and used `F:\arr-fork\.dotnet\dotnet.exe` for Prowlarr compilation.
- Re-ran Prowlarr backend compile without installer generation: cleaned Debug/Release, then ran the documented `win-x64` publish build with NuGet v2 restore source; it passed and produced `_output/net8.0-windows/win-x64/publish/Prowlarr.exe`, `_output/net8.0/win-x64/publish/Prowlarr.Console.exe`, and `_output/Prowlarr.Update/net8.0/win-x64/publish/Prowlarr.Update.exe`.
- Re-ran Prowlarr frontend production webpack build without installer generation; it passed and produced `_output/UI/index.html`.
