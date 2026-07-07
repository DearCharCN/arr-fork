# Project Changelog

Record implemented user-visible project and feature changes here.

Do not record draft requirements, planned work, routine AI activity, command runs, setup steps, or status checks here.

## 2026-07-03

- Added initial R001 Prowlarr support for M-Team media metadata: search results can now carry audio languages, subtitle languages, and per-language audio specifications, with desktop/mobile search UI columns and Torznab/Newznab metadata output.
- Added M-Team API access documentation and the `mteam-api` project skill for safe token-based real-environment probes across M-Team related work.
- Updated R001 M-Team parsing against real API samples: full per-track media data was found in detail `mediainfo` text, and the parser now handles both MediaInfo track sections and BDInfo audio/subtitle tables.
- Updated R001 M-Team enrichment strategy: when search results do not include parseable track metadata, Prowlarr now fetches `POST /api/torrent/mediaInfo?id=<torrent id>` and parses the returned MediaInfo text for audio languages, subtitle languages, and per-language audio specifications.
- Refined R001 search-result media display: Prowlarr now shows compact multi-audio and multi-subtitle labels in desktop/mobile search results, exposes full media details in popovers, and preserves Atmos in parsed audio specifications.
- Improved R001 M-Team search latency without dropping later results: MediaInfo enrichment now covers the full 100-result M-Team page by default, caches successful per-torrent MediaInfo responses for 7 days, and rate-limits MediaInfo requests to reduce "too frequent" failures.
- Added Radarr R001 downstream support: Radarr now parses Prowlarr Torznab/Newznab `audio` and `subs` attributes, returns them from the release API, and shows compact media-info details in interactive search results.

## 2026-07-04

- Refined Prowlarr R001 MediaInfo enrichment to return M-Team search results immediately, mark uncached rows as pending, fetch `/api/torrent/mediaInfo` through a per-release search API endpoint, and update each desktop/mobile search-result row in place with reused spinner loading indicators for audio/subtitle cells.

## 2026-07-07

- Refined Prowlarr R001 search-result UI: audio/subtitle headers now align with their row cells, audio and subtitle columns can be manually sorted, pending or empty media-info rows sort last, and the footer shows MediaInfo enrichment progress until completion.
- Extended Prowlarr R001 search results so Custom Filters can filter by audio/subtitle text, and MediaInfo enrichment progress is now included in API and Torznab/Newznab release data as backend-tracked search-result state.
