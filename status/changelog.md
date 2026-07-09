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
- Extended Radarr R001 downstream support: Radarr now preserves Prowlarr media-info status/progress fields, shows pending media data with row-level loading and overall progress in interactive search, keeps MediaInfo sorting stable until the user sorts again, and waits for pending media data before automatic search decisions continue.
- Refined Radarr R001 interactive search display: audio info, subtitle languages, and additional-data status now appear as separate sortable columns instead of being hidden behind one combined MediaInfo column.
- Fixed Radarr R001 MediaInfo enrichment so Radarr now proxies per-row additional-data requests back to Prowlarr instead of passively re-searching; pending interactive-search rows update individually, and automatic searches actively enrich pending rows before making download decisions.
- Fixed Prowlarr R001 downstream MediaInfo enrichment for Radarr and other Torznab/Newznab consumers: downstream search results are now cached with shared MediaInfo progress state, so follow-up `/api/v1/search/mediaInfo` requests can enrich the exact release returned to the downstream app.
- Refined Radarr R001 interactive search display again: the Additional Data column was removed in favor of the header progress alert, loaded audio/subtitle cells stop showing row spinners individually, and long media details are shown through compact labels with hover popovers.
- Added R005 nested Custom Filter support in Prowlarr and Radarr: custom filters can now use grouped `and`/`or` condition trees in the editor and client-side filtering logic, while simple flat AND filters keep the legacy storage shape for compatibility.
- Fixed R005 nested Custom Filter editing in Prowlarr and Radarr so add-condition/add-group controls in a nested group modify that current group, and filtered release/search result tables now show rows once newly fetched additional data makes them match the active filter.
- Fixed Prowlarr search MediaInfo progress display so the footer uses the latest returned progress across enriched rows instead of getting stuck on an older row's `Querying additional data 1/100` state.
- Fixed Prowlarr M-Team MediaInfo enrichment under origin rate limiting: search-result additional-data requests now run serially, use the M-Team indexer's 5-second rate limit, keep rate-limited rows pending instead of marking them unavailable, retry pending rows with delay, and only advance overall progress once a row actually leaves pending state.

## 2026-07-08

- Added endpoint-aware M-Team additional-data scheduling in Prowlarr: MediaInfo and detail requests now have separate paced workers, endpoint-specific cooldowns, rate-limit rollback to the original queue, expiring cancellable handles, and a cancellation API for pending additional-data requests.
- Updated Prowlarr and Radarr search enrichment to use windowed handle-based polling, so interactive searches create only a small active set of additional-data tasks at a time while continuing through the full result set as rows complete.
- Updated Radarr automatic search enrichment so the four-row window limits task creation only; automatic decisions still wait for the required pending candidates to complete or time out before proceeding.
- Fixed additional-data handle isolation across Prowlarr UI and Radarr: multiple handles can now observe one shared task result without leaking caller handles through shared release caches, handle renewal refreshes the shared task TTL, and tasks are canceled once all handles expire or are canceled.

## 2026-07-09

- Fixed R001 additional-data progress accounting so each Prowlarr MediaInfo search session counts completed releases independently, even when another Prowlarr/Radarr session completes the same cached torrent first.
- Updated Prowlarr/Radarr additional-data progress totals to use the full displayed result set, so cached rows count as already completed, for example `35/60` instead of `0/25`.
- Moved Radarr interactive-search additional-data progress into the modal footer so it remains visible while the result table scrolls.
- Refined Prowlarr Audio/Subtitle sorting so completed-but-empty media rows and pending/not-yet-requested media rows are kept in separate sort groups instead of being mixed together as the same empty value.
- Added Radarr R006 backend release selection controls: Release Filter Profiles, Audio Language Mappings, Audio Score Profiles, Audio Language Preferences, and Custom Format Mutex Groups can now drive Quality Profile decisions and automatic release ordering.
- Added Radarr interactive-search selected-audio and audio-score output, including score breakdown popovers and custom filter/sort fields for the selected audio result.
- Added a Radarr Release Scoring settings page with create/edit/delete modals for Audio Language Mappings, Audio Score Profiles, Audio Language Preferences, and Custom Format Mutex Groups.
- Added the Release Scoring entry to Radarr's left Settings sidebar menu.
