# M-Team API Notes

Source: https://wiki.m-team.cc/zh-tw/api
Checked: 2026-07-03

## Authentication

M-Team documents third-party API access through an API Access Token. Send the token as the `x-api-key` request header. Do not use cookie-based access for third-party tools.

The user supplied a token for this workspace on 2026-07-03. Do not persist the raw token in tracked files. Its fingerprint is `019f1f20...4933`; set the raw value only in the local `MTEAM_API_TOKEN` environment variable when probing.

## Documentation Caveat

The wiki points to Swagger at `https://test2.m-team.cc/api/swagger-ui.html` after logging into the test site. The wiki also warns that Swagger details may be imperfect, including request body format and required parameter accuracy. Compare docs with actual browser/API behavior when results disagree.

## Base URLs

Known production API pattern from Prowlarr:

- Site base: `https://kp.m-team.cc/`, `https://tp.m-team.cc/`, or `https://pt.m-team.cc/`
- API base derived by Prowlarr: `https://api.m-team.cc`
- Production frontend also lists `https://api.m-team.io/api` as an API host. A profile smoke test succeeded there on 2026-07-03 with the same response shape. Treat it as an alternate host, not a proven separate quota pool.
- `https://api2.m-team.cc/api/member/profile` returned HTTP 403 in the same smoke test.

Test-site Swagger is under `https://test2.m-team.cc/api/swagger-ui.html`; actual test API paths may use the same host with `/api/...` after login.

## Important Endpoints

Prowlarr currently uses:

- `POST /api/torrent/search`
- `POST /api/torrent/genDlToken?id=<torrent id>`

For deeper field discovery, also probe if available:

- `/api/torrent/detail`
- `/api/torrent/mediaInfo`
- `/api/member/profile` for authentication smoke tests

Observed from the production web frontend on 2026-07-03:

- `/api/torrent/mediaInfo`
  - Reads only the MediaInfo text for one torrent.
  - Works with `POST /api/torrent/mediaInfo?id=<torrent id>` or form body `id=<torrent id>`.
  - JSON body `{ "id": "<torrent id>" }` returned `參數錯誤`.
  - The response body contains `data` as the MediaInfo text. This is enough for R001 audio/subtitle parsing and is smaller than `/api/torrent/detail`.
  - It did not return visible rate/quota headers in a live probe.
- `/api/torrent/files`
  - Reads a torrent's file list by form body `id=<torrent id>`.
  - It returns file names and sizes only; it did not include embedded audio/subtitle track metadata.
- `/api/subtitle/list`
  - Reads site-hosted subtitle uploads for one torrent by form body `id=<torrent id>`.
  - This is not the torrent's embedded subtitle track list.
- `/api/subtitle/search`
  - Searches the site subtitle library and returns subtitle upload records with a `lang` id.
  - This is not tied to the media tracks inside the release payload.
- `/api/torrent/audioCodecList`
  - Returns the global audio-codec lookup table.
  - Search results carry an `audioCodec` id, but this does not preserve per-language audio specs.
- `/api/tracker/queryHistory`
  - Batch query for user's torrent history/peer state by `tids`.
  - It does not include media metadata.

No published separate quota was found for `/api/torrent/mediaInfo`. Treat it as a better-fit endpoint for media metadata, but not as proven unlimited or proven outside global API abuse limits.

Observed `/api/torrent/mediaInfo` rate-limit behavior on 2026-07-08:

- The endpoint can return HTTP 200 with API `code=1`, message `請求過於頻繁`, and empty `data`. Treat this message as retryable rate limiting even when the HTTP status is successful.
- Small fixed-interval batches down to 1 second succeeded in live probes, including 20 attempts at 1-second spacing plus baseline.
- Zero-delay burst limits were stateful and inconsistent, triggering at attempts 13, 18, or 20 in separate runs; one 25-request burst did not trigger.
- Recovery is not fixed. One light event recovered after 60 seconds, while later events remained limited after quiet waits of 120, 180, 300, and 600 seconds.
- Failed recovery probes may extend or refresh the server-side window. After a limit event, stop the active batch and avoid frequent recovery polling.

Recommended MediaInfo enrichment policy: single concurrency, cache successful responses by torrent id, use a small delay between successful calls, and on `請求過於頻繁` stop the active batch and back off for at least 30 minutes, growing toward 60 minutes after repeated events.

## Request Shape Used By Prowlarr

Search request:

```json
{
  "mode": "Normal",
  "categories": [],
  "pageNumber": 1,
  "pageSize": 1,
  "keyword": "optional search text",
  "imdb": "optional imdb id",
  "discount": "FREE"
}
```

Headers:

```text
x-api-key: <MTEAM_API_TOKEN>
Accept: application/json
Content-Type: application/json
```

## Wiki Restrictions And Limits

The wiki says these prefixes are not allowed for third-party calls:

- `/admin/**`
- `/login`
- `/apikey/**`

It lists allowed subsets under `/member/**`, including profile/base and some user torrent/login history endpoints, and under `/msg/**`, including message statistics endpoints.

Published suggested limits include:

- `/torrent/search`: 1000 calls per roughly 24 hours
- `/torrent/detail`: 100 calls per hour
- Torrent download quota: 1000 per day
- Torrent download behavior: 100 per hour

Use tiny probes and avoid download-token calls unless they are necessary.

## Real-Data Discovery Checklist

1. Run `Profile` to confirm the token works.
2. Run `Search` with `PageSize 1`; save sanitized JSON under `tmp/`.
3. Inspect response root, usually `data.data[]`.
4. Record actual field names and nesting for the behavior being implemented.
5. If search omits needed details, run `Detail` for a single result id.
6. Save a sanitized minimal response that preserves the fields needed by the current feature.
7. Update the relevant parser fixture or documentation, then run the appropriate documented build skill.

