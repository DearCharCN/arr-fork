---
name: mteam-api
description: Validate and inspect M-Team API access for any M-Team related development or real-data testing. Use when Codex needs to probe M-Team endpoints, confirm request/response fields, capture sanitized fixtures, investigate tracker behavior, or debug x-api-key token based API access without using cookies.
---

# M-Team API

## Core Rules

- Treat the API token as a secret. Do not write the raw token into tracked docs, fixtures, logs, commits, or final answers.
- Read the token from `MTEAM_API_TOKEN`; if the user provides a token in chat, use it only for the current request or ask them to set the env var.
- Use the `x-api-key` HTTP header. Do not use cookies for third-party API access.
- Prefer small probes: `pageSize=1` for search and a single torrent id for detail.
- Keep saved responses under `tmp/` and save only sanitized JSON unless the user explicitly requests a raw local capture.

## References

- Read `references/api-notes.md` before probing endpoints or updating parser fixtures.
- Use `scripts/Invoke-MTeamApiProbe.ps1` for repeatable local probes.

## Probe Workflow

From `G:\arr-fork`:

```powershell
$env:MTEAM_API_TOKEN = '<token from local secret storage>'
```

Smoke-test authentication:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 -Operation Profile
```

Probe search with a tiny page:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 `
  -Operation Search `
  -Keyword 'example title' `
  -PageSize 1 `
  -OutFile tmp\mteam-search.redacted.json
```

If the search result does not include media fields, inspect one result with detail:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 `
  -Operation Detail `
  -TorrentId '<torrent id>' `
  -OutFile tmp\mteam-detail.redacted.json
```

Only generate a download token when explicitly needed; it can count against download-related limits:

```powershell
.\.codex\skills\mteam-api\scripts\Invoke-MTeamApiProbe.ps1 `
  -Operation DownloadToken `
  -TorrentId '<torrent id>' `
  -AllowDownloadToken
```

## Applying Results

- Use the smallest endpoint and payload that proves the behavior being tested.
- Preserve real response shape in sanitized captures so parser fixtures can be updated accurately.
- For media metadata work, preserve language-to-spec relationships, such as `English: TrueHD` and `Chinese: DDP 5.1`.
- When code changes depend on the observed response, update the relevant parser fixture with a sanitized representative sample.
- Re-run the appropriate documented build skill after parser, sync, or UI changes.

