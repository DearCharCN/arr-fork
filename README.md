# Arr Fork Workspace

This folder is a coordination workspace for cross-repository development across Prowlarr, Sonarr, and Radarr.

The source repositories are independent Git repositories:

- `Prowlarr/`
- `Sonarr/`
- `Radarr/`

The workspace root is used for planning, AI context, status tracking, and helper scripts. It should not directly own the source history of the three repositories.

## Repository Layout

```text
arr-fork/
  AGENTS.md
  INDEX.md
  README.md
  .gitignore
  repos.json

  planning/
    requirements.md
    ideas.md
    decisions.md

  status/
    current.md
    log.md
    changelog.md

  guides/
    repo-map.md

  scripts/
    setup.ps1
    status.ps1
    sync.ps1

  Prowlarr/   # independent Git repository
  Sonarr/     # independent Git repository
  Radarr/     # independent Git repository
```

## Git Rules

- Keep application code changes inside `Prowlarr/`, `Sonarr/`, or `Radarr/`.
- Keep cross-repository planning and AI context in the workspace root.
- Do not commit the nested repository folders into the workspace root repository.
- Report Git status separately for each touched repository.

## AI Context

Start with:

- `AGENTS.md`
- `INDEX.md`
- `planning/requirements.md`
- `status/current.md`
- `status/log.md`
- `guides/repo-map.md`

Build, debug, test, and release instructions are intentionally not documented yet. They should be added only after running through the real local workflow with the user.

## Setup On Another Machine

Clone this workspace repository, then run:

```powershell
.\scripts\setup.ps1
```

This reads `repos.json` and clones any missing source repositories.

## Check Repository Status

Run:

```powershell
.\scripts\status.ps1
```

This prints the current branch and short Git status for each source repository.

## Sync Repository Remotes

Run:

```powershell
.\scripts\sync.ps1
```

This fetches all remotes for each source repository without changing branches or working tree files.
