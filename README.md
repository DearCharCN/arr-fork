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
  README.md
  .gitignore
  repos.json

  scripts/
    setup.ps1
    status.ps1

  Prowlarr/   # independent Git repository
  Sonarr/     # independent Git repository
  Radarr/     # independent Git repository
```

## Git Rules

- Keep application code changes inside `Prowlarr/`, `Sonarr/`, or `Radarr/`.
- Keep cross-repository planning and AI context in the workspace root.
- Do not commit the nested repository folders into the workspace root repository.
- Report Git status separately for each touched repository.

## Next Structure To Add

```text
arr-fork/
  AGENTS.md
  INDEX.md

  planning/
    requirements.md
    ideas.md
    decisions.md

  status/
    current.md
    changelog.md

  guides/
    repo-map.md
    build-debug-release.md

  scripts/
    sync.ps1
```

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
