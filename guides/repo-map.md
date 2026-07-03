# Repository Map

This guide records stable repository roles and important paths. Update it when confirmed by code exploration.

## Prowlarr

Role: Indexer manager and search integration.

Important paths:

- `Prowlarr/src/`
- `Prowlarr/frontend/`
- `Prowlarr/schemas/`
- `Prowlarr/distribution/`

Known solution file:

- `Prowlarr/src/Prowlarr.sln`

## Sonarr

Role: TV library and download automation.

Important paths:

- `Sonarr/src/`
- `Sonarr/frontend/`
- `Sonarr/schemas/`
- `Sonarr/distribution/`
- `Sonarr/docker/`

Known solution file:

- `Sonarr/src/Sonarr.sln`

## Radarr

Role: Movie library and download automation.

Important paths:

- `Radarr/src/`
- `Radarr/frontend/`
- `Radarr/schemas/`
- `Radarr/distribution/`

Known solution file:

- `Radarr/src/Radarr.sln`

## Cross-Repository Notes

- The three repositories share similar `src/`, `frontend/`, `schemas/`, and `distribution/` layouts.
- Prowlarr and Radarr include root-level `build.sh`, `docs.sh`, and `test.sh`.
- Sonarr stores similar shell scripts under `Sonarr/scripts/`.
- Build, debug, test, and release instructions are intentionally not documented yet.
