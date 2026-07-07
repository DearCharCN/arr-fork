# Workspace Index

This is the entry point for understanding the `arr-fork` workspace.

## Read Order For AI

1. `AGENTS.md`
   - Workspace rules and AI behavior.

2. `planning/requirements.md`
   - User-owned requirements and planned features.

3. `status/current.md`
   - AI-maintained current progress and next steps.

4. `status/log.md`
   - Chronological AI activity and command notes.

5. `planning/decisions.md`
   - Decisions that should not be repeatedly reopened.

6. `guides/repo-map.md`
   - Stable repository roles and important paths.

7. `repos.json`
   - Machine-readable repository list.

## Main Areas

| Path | Owner | Purpose |
| --- | --- | --- |
| `planning/requirements.md` | User | Requirements that should be implemented |
| `planning/ideas.md` | User | Raw ideas and future possibilities |
| `planning/decisions.md` | User + AI | Accepted decisions and rationale |
| `status/current.md` | AI | Current implementation state |
| `status/log.md` | AI | Chronological AI activity log |
| `status/changelog.md` | AI | Implemented user-visible project and feature change log |
| `guides/repo-map.md` | User + AI | Repository roles and stable code locations |
| `repos.json` | User + AI | Repo paths, remotes, branches, and roles |
| `scripts/` | User + AI | Workspace helper scripts |
| `.codex/skills/build-prowlarr/` | AI | Verified Prowlarr local build and installer workflow |
| `.codex/skills/build-radarr/` | AI | Verified Radarr local build workflow |
| `.codex/skills/build-sonarr/` | AI | Verified Sonarr local build and installer workflow |
| `.codex/skills/mteam-api/` | AI | Safe M-Team API probing workflow for M-Team real-environment validation |

## Source Repositories

- `Prowlarr/`
- `Sonarr/`
- `Radarr/`

These folders are ignored by the workspace root Git repository and keep their own Git histories.

## Local Compiled-Version Run Rule

When the user asks to run a compiled Prowlarr, Radarr, or Sonarr build, first find any currently running stable installed process for that app, record its executable path or service identity, then stop/kill it before starting the compiled build from this workspace. This avoids port and profile conflicts between the stable install and the temporary development build.

When the user asks to stop or end the compiled build, inspect the currently running process path first. Only kill it if it is clearly running from this workspace's compiled output or artifact folders. Then restart the recorded stable installed executable or service. If the stable install path or service identity was not recorded and discovery is ambiguous, ask the user before starting anything.

## Project Skills

- `.codex/skills/build-prowlarr/SKILL.md`
  - Use when asked to compile, package, run the compiled build, stop the compiled build, or build a Windows installer for Prowlarr locally.
  - Captures the verified NuGet v2 restore workaround, Windows build, frontend build, local compiled/stable run switching, and Inno installer generation.

- `.codex/skills/build-radarr/SKILL.md`
  - Use when asked to compile, build, run the compiled build, or stop the compiled build for Radarr locally.
  - Captures the verified Windows workflow, local compiled/stable run switching, and known pitfalls from the first successful run.

- `.codex/skills/build-sonarr/SKILL.md`
  - Use when asked to compile, package, run the compiled build, stop the compiled build, or build a Windows installer for Sonarr locally.
  - Captures the verified .NET 6 SDK setup, Windows build, frontend build, package folder, local compiled/stable run switching, and bundled Inno installer generation.

- `.codex/skills/mteam-api/SKILL.md`
  - Use when asked to validate M-Team API access or inspect real M-Team search/detail response fields.
  - Captures token handling, `x-api-key` access, tiny probe commands, response sanitization, and reusable real-data discovery workflow.
