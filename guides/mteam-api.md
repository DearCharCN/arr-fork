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

## Rate And Scope Notes

The wiki lists disallowed third-party prefixes such as `/admin/**`, `/login`, and `/apikey/**`.

Published suggested limits include roughly:

- `/torrent/search`: 1000 calls per 24 hours.
- `/torrent/detail`: 100 calls per hour.
- Torrent download quota: 1000 per day.
- Torrent download behavior: 100 per hour.

Keep probes small and save only sanitized JSON under `tmp/`.
