# M-Team API Access

This guide records the API access facts needed for M-Team related development and real-environment validation.

Source: https://wiki.m-team.cc/zh-tw/api
Checked: 2026-07-03

## Token Handling

The user supplied an M-Team API token for this workspace on 2026-07-03. The raw token is intentionally not stored in tracked documentation. Its fingerprint is `019f1f20...4933`.

For local testing, set the token only in the current PowerShell session:

```powershell
$env:MTEAM_API_TOKEN = '<raw token from private local storage>'
```

Do not commit the raw token, raw API captures, cookies, or profile responses.

## Documented Access Pattern

M-Team documents API Access Token usage for third-party tools. Pass the token in the `x-api-key` HTTP header. Do not use cookie-based access for third-party API calls.

The wiki points to Swagger at `https://test2.m-team.cc/api/swagger-ui.html` after logging into the test site, but warns that the Swagger request formats and required fields may be inaccurate. Treat real API probes as the source of truth when Swagger and behavior disagree.

## Probe Endpoints

Production base URL used by Prowlarr:

```text
https://api.m-team.cc
```

Primary probe endpoints:

- `POST /api/member/profile` for token smoke tests.
- `POST /api/torrent/search` for M-Team search result fields.
- `/api/torrent/detail` for one-result media-info confirmation if search results omit audio/subtitle details.
- `POST /api/torrent/mediaInfo?id=<torrent id>` for the lightweight MediaInfo text used by R001 enrichment.
- `POST /api/torrent/genDlToken?id=<torrent id>` only when intentionally testing download token behavior.

Prowlarr currently sends search requests as JSON with `mode`, `categories`, `pageNumber`, `pageSize`, and optional `keyword`, `imdb`, and `discount`.

## Safe Probe Commands

Use the project skill:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 -Operation Profile
```

Tiny search probe:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 `
  -Operation Search `
  -Keyword 'example title' `
  -PageSize 1 `
  -OutFile tmp\mteam-search.redacted.json
```

Detail probe after selecting one torrent id:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 `
  -Operation Detail `
  -TorrentId '<torrent id>' `
  -OutFile tmp\mteam-detail.redacted.json
```

MediaInfo rate-limit probe:

```powershell
$env:MTEAM_API_TOKEN = '<raw token from private local storage>'
.\scripts\Measure-MTeamMediaInfoRateLimit.ps1 -Keyword 'Titanic' -BaselineOnly
```

Use `-BaselineOnly` after a quiet period to check whether the endpoint has recovered without adding extra recovery probes. Use interval and burst options only when intentionally measuring limits:

```powershell
.\scripts\Measure-MTeamMediaInfoRateLimit.ps1 `
  -Keyword 'Titanic' `
  -SkipBurst `
  -IntervalAttempts 5 `
  -IntervalsSeconds 2,1
```

## Rate And Scope Notes

The wiki lists disallowed third-party prefixes such as `/admin/**`, `/login`, and `/apikey/**`.

Published suggested limits include roughly:

- `/torrent/search`: 1000 calls per 24 hours.
- `/torrent/detail`: 100 calls per hour.
- Torrent download quota: 1000 per day.
- Torrent download behavior: 100 per hour.

Keep probes small and save only sanitized JSON under `tmp/`.

## Observed `/torrent/mediaInfo` Rate-Limit Behavior

Observed: 2026-07-08, using one `Titanic` search result id and sanitized captures under `tmp/mteam-mediainfo-rate-limit/`.

- The endpoint can return HTTP 200 with API `code=1`, message `請求過於頻繁`, and empty `data`; do not rely on HTTP 429 alone.
- Successful response bodies contain MediaInfo text in `data`; saved rate-limit captures intentionally keep only status, timing, message, and data length.
- Single-threaded fixed intervals worked for limited batches down to 1 second. Samples: 3/5/10/15/20/30/45/60 seconds each succeeded for three attempts, 2/1 seconds succeeded for five attempts, and 1 second succeeded for 20 attempts plus baseline.
- Zero-delay bursts are risky and inconsistent. Samples triggered at attempt 20, attempt 18, and attempt 13 in separate runs; another 25-request burst did not trigger. Treat the threshold as stateful, not a fixed number.
- Recovery is not deterministic. A light event recovered after a 60-second quiet wait, but later events remained limited after 30, roughly 60, 120, 180, 300, and 600 seconds of quiet waiting.
- Failed recovery probes may extend or refresh the server-side window. After `請求過於頻繁`, stop the whole MediaInfo batch instead of polling frequently.

Operational guidance for Prowlarr-style enrichment:

- Keep MediaInfo enrichment single-concurrency.
- A 1-3 second minimum delay is acceptable for small batches, but a more conservative default such as 5 seconds is reasonable while the endpoint's global quota behavior remains undocumented.
- On `請求過於頻繁`, preserve pending state if the UI can retry later, stop the current batch, and back off for at least 30 minutes; repeated events should back off toward 60 minutes.
- Cache successful MediaInfo responses aggressively by torrent id to avoid repeated calls.
