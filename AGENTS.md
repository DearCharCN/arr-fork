# AI Workspace Instructions

This workspace coordinates cross-repository development for Prowlarr, Sonarr, and Radarr.

## Start Here

When starting work in this workspace, read these files in order:

1. `INDEX.md`
2. `planning/requirements.md`
3. `status/current.md`
4. `planning/decisions.md`
5. `guides/repo-map.md`
6. `repos.json`

Do not assume build, test, debug, or release commands until they have been documented after a real local run with the user.

## Repository Boundaries

The source repositories live in:

- `Prowlarr/`
- `Sonarr/`
- `Radarr/`

Each source repository is an independent Git repository. The workspace root is only for planning, AI context, status tracking, and helper scripts.

## File Ownership

- The user owns `planning/requirements.md` and `planning/ideas.md`.
- The AI may update `status/current.md`, `status/changelog.md`, and `planning/decisions.md`.
- The AI may update `guides/repo-map.md` when it learns stable project structure.
- The AI should not rewrite user requirements unless explicitly asked.

## Working Rules

- Keep application code changes inside `Prowlarr/`, `Sonarr/`, or `Radarr/`.
- Keep cross-repository planning and status in the workspace root.
- Report Git status separately for each touched source repository.
- When changing cross-repo behavior, update `planning/decisions.md` or `status/current.md` as appropriate.
- Prefer existing patterns inside each repository over introducing new shared abstractions.
- Do not create build, test, debug, or release documentation from guesses.
