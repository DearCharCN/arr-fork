# Decisions

Use this file to record decisions that should not be repeatedly reopened in future AI sessions.

## D001 - Use `/torrent/mediaInfo` for M-Team R001 enrichment

Date: 2026-07-03
Related Requirement: R001

### Decision

Prowlarr's M-Team indexer should derive R001 audio languages, subtitle languages, and per-language audio specifications from the torrent's MediaInfo text. When a search result does not already include parseable media track metadata, the search response marks that release as pending and the Prowlarr search API fetches `POST /api/torrent/mediaInfo?id=<torrent id>` on a per-release follow-up request. The frontend updates each row as its follow-up request returns.

### Reason

Real `/api/torrent/search` responses only expose summary fields such as `audioCodec`, `videoCodec`, and `hasChineseSubtitle`; they do not preserve per-track language-to-spec relationships. `/api/torrent/detail` contains the needed `mediainfo` text but has a published 100/hour limit. `/api/torrent/mediaInfo` returns the same kind of text directly with a smaller payload, and no separate published quota was found.

### Consequences

- R001 must not infer embedded audio/subtitle tracks from the release title.
- R001 can preserve cases like `English: TrueHD 7.1` and `Chinese: DDP 5.1`.
- Initial M-Team search results should return without waiting for uncached MediaInfo requests.
- The frontend should display a per-cell loading state while each row's MediaInfo request is pending and update that row in place when it returns.
- MediaInfo enrichment should degrade gracefully if requests fail or are rate limited, because the endpoint's quota behavior is undocumented.
