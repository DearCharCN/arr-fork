# Project Changelog

Record user-visible project, requirement, and feature changes here.

Do not record routine AI activity, command runs, setup steps, or status checks here.

## 2026-07-03

- Recorded initial draft requirements R001-R004 in `planning/requirements.md`: Prowlarr M-Team media language metadata, Sonarr/Radarr custom search-result sorting, per-quality-profile Custom Format score priority, and Sonarr season pack search/tracking.
- Added initial R001 Prowlarr support for M-Team media metadata: search results can now carry audio languages, subtitle languages, and per-language audio specifications, with desktop/mobile search UI columns and Torznab/Newznab metadata output.
- Added M-Team API access documentation and the `mteam-api` project skill for safe token-based real-environment probes across M-Team related work.
- Updated R001 M-Team parsing against real API samples: full per-track media data was found in detail `mediainfo` text, and the parser now handles both MediaInfo track sections and BDInfo audio/subtitle tables.
- Updated R001 M-Team enrichment strategy: when search results do not include parseable track metadata, Prowlarr now fetches `POST /api/torrent/mediaInfo?id=<torrent id>` and parses the returned MediaInfo text for audio languages, subtitle languages, and per-language audio specifications.
- Refined R001 search-result media display: Prowlarr now shows compact multi-audio and multi-subtitle labels in desktop/mobile search results, exposes full media details in popovers, and preserves Atmos in parsed audio specifications.
