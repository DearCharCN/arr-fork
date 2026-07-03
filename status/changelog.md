# AI Changelog

Record AI-assisted workspace and implementation changes here in chronological order.

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
