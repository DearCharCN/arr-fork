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
