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

Cycle/backoff probe:

```powershell
.\scripts\Measure-MTeamMediaInfoCycleLimit.ps1 `
  -TorrentId '1202530' `
  -IntervalSeconds 1 `
  -TotalRequestsTarget 1000 `
  -SuccessTarget 200 `
  -InitialBackoffMinutes 5 `
  -BackoffIncrementMinutes 1
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
- Single-threaded fixed intervals worked for limited batches down to 1 second. Samples: 3/5/10/15/20/30/45/60 seconds each succeeded for three attempts, 2/1 seconds succeeded for five attempts, and 1 second succeeded for 20 attempts plus baseline. Longer runs failed: 1-second spacing hit `請求過於頻繁` at attempt 25, 2-second spacing at attempt 49, 3-second spacing at attempt 50, and 5-second spacing at attempt 25.
- Zero-delay bursts are risky and inconsistent. Samples triggered at attempt 20, attempt 18, and attempt 13 in separate runs; another 25-request burst did not trigger. Treat the threshold as stateful, not a fixed number.
- Recovery is not deterministic. A light event recovered after a 60-second quiet wait, but later events remained limited after 30, roughly 60, 120, 180, 300, and 600 seconds of quiet waiting.
- A cycle test with 1-second active spacing and 5-minute backoff reached 100 total requests: cycle 1 failed at total request 51, the 5-minute backoff check succeeded, cycle 2 failed at total request 77, the next 5-minute backoff check succeeded, and cycle 3 reached request 100 without another failure.
- A longer cycle test stopped at 200 successful MediaInfo responses with 209 total requests and 9 rate-limit responses. With 1-second active spacing, cycles 1, 2, and 3 each failed on their 51st active request. The first two 5-minute backoff checks succeeded. After the third failure, 5-, 6-, 7-, 8-, 9-, and 10-minute backoff checks still returned `請求過於頻繁`; the 11-minute check succeeded, and the fourth active cycle continued until the success target was reached.
- A 10-second active-spacing cycle test stopped at 360 successful MediaInfo responses with 370 total requests and 10 rate-limit responses. The first active cycle failed at attempt 101; 5-, 6-, 7-, and 8-minute backoff checks failed, and the 9-minute check succeeded. The second active cycle failed at attempt 151 with the same 9-minute recovery pattern. The third active cycle reached the success target without another failure.
- A cross-endpoint probe checked `/api/torrent/detail` before and immediately after forcing `/api/torrent/mediaInfo` to return `請求過於頻繁`. `detail` succeeded both times and returned a `mediainfo` field, while `mediaInfo` failed on the 51st 1-second-spaced attempt. This suggests the observed `mediaInfo` limiter is not an immediate whole-token block for `detail`, though it does not rule out a higher-level global quota or separate `detail` quota.
- A dual-endpoint alternating probe used `/api/torrent/mediaInfo` and `/api/torrent/detail` with a global 10-second request interval, so each endpoint had a minimum 20-second interval. When one endpoint returned `請求過於頻繁`, only that endpoint cooled for 12 minutes while the other endpoint kept its 20-second cadence. The run stopped at 500 successful responses after 506 total requests: 250 successes from each endpoint, 2 rate-limit responses from each endpoint, and 2 transient HTTP 502 transport errors. This confirms the endpoint-specific cooldown strategy can keep useful throughput going while one endpoint is cooling.
- A same-account token-switch probe checked two API tokens against `/api/torrent/mediaInfo`. Both tokens succeeded at baseline. Token A then hit `請求過於頻繁` on the 49th 1-second-spaced trigger attempt, and an immediate request with token B also returned `請求過於頻繁`; a follow-up with token A remained limited. In this trial, switching to another token for the same account did not bypass the `mediaInfo` limiter. The probe cannot distinguish account-level from IP-level limiting, but it rules out a simple per-token-only limiter for this case.
- Failed recovery probes may extend or refresh the server-side window. After `請求過於頻繁`, stop the whole MediaInfo batch instead of polling frequently.

## Observed `/torrent/detail` Rate-Limit Behavior

Observed: 2026-07-08, using the same `Titanic` search result id and sanitized captures under `tmp/mteam-mediainfo-rate-limit/`.

- The endpoint can also return HTTP 200 with API `code=1`, message `請求過於頻繁`, and empty or missing useful `data`.
- In a 1-second spacing probe, the baseline detail request succeeded, interval attempts 1-49 succeeded, and interval attempt 50 returned `請求過於頻繁`.
- Immediately after `detail` returned `請求過於頻繁`, a single `/api/torrent/mediaInfo` request for the same torrent still returned `SUCCESS`. Together with the inverse cross-endpoint probe above, this suggests `detail` and `mediaInfo` are not blocked by the same immediate per-token limiter, though each endpoint can still have its own quota and a higher-level quota may still exist.
- In the dual-endpoint 20-second-per-endpoint probe, `detail` returned `請求過於頻繁` at endpoint attempts 1 and 152. After each 12-minute endpoint-specific cooldown it returned to `SUCCESS`, while `mediaInfo` continued independently when available.

Operational guidance for Prowlarr-style enrichment:

- Keep MediaInfo enrichment single-concurrency.
- A 1-5 second minimum delay is acceptable only for small batches. Ten-second spacing lasted longer but still triggered rate limiting in long runs, at active attempts 101 and 151 in one 360-success probe. For longer enrichment runs, use a per-batch cap or a much longer quiet backoff.
- On `請求過於頻繁`, preserve pending state if the UI can retry later, stop the current batch, and back off for at least 30 minutes; repeated events should back off toward 60 minutes.
- Cache successful MediaInfo responses aggressively by torrent id to avoid repeated calls.
