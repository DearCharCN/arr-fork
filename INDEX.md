# Workspace Index

This is the entry point for understanding the `arr-fork` workspace.

## Read Order For AI

1. `AGENTS.md`
   - Workspace rules and AI behavior.

2. `planning/requirements.md`
   - User-owned requirements and planned features.

3. `status/current.md`
   - AI-maintained current progress and next steps.

4. `planning/decisions.md`
   - Decisions that should not be repeatedly reopened.

5. `guides/repo-map.md`
   - Stable repository roles and important paths.

6. `repos.json`
   - Machine-readable repository list.

## Main Areas

| Path | Owner | Purpose |
| --- | --- | --- |
| `planning/requirements.md` | User | Requirements that should be implemented |
| `planning/ideas.md` | User | Raw ideas and future possibilities |
| `planning/decisions.md` | User + AI | Accepted decisions and rationale |
| `status/current.md` | AI | Current implementation state |
| `status/changelog.md` | AI | Chronological AI work log |
| `guides/repo-map.md` | User + AI | Repository roles and stable code locations |
| `repos.json` | User + AI | Repo paths, remotes, branches, and roles |
| `scripts/` | User + AI | Workspace helper scripts |
| `.codex/skills/build-prowlarr/` | AI | Verified Prowlarr local build and installer workflow |
| `.codex/skills/build-radarr/` | AI | Verified Radarr local build workflow |

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
