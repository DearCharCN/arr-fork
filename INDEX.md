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

## Project Skills

- `.codex/skills/build-prowlarr/SKILL.md`
  - Use when asked to compile, package, or build a Windows installer for Prowlarr locally.
  - Captures the verified NuGet v2 restore workaround, Windows build, frontend build, and Inno installer generation.

- `.codex/skills/build-radarr/SKILL.md`
  - Use when asked to compile or build Radarr locally.
  - Captures the verified Windows workflow and known pitfalls from the first successful run.

- `.codex/skills/build-sonarr/SKILL.md`
  - Use when asked to compile, package, or build a Windows installer for Sonarr locally.
  - Captures the verified .NET 6 SDK setup, Windows build, frontend build, package folder, and bundled Inno installer generation.

- `.codex/skills/mteam-api/SKILL.md`
  - Use when asked to validate M-Team API access or inspect real M-Team search/detail response fields.
  - Captures token handling, `x-api-key` access, tiny probe commands, response sanitization, and reusable real-data discovery workflow.
