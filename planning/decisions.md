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

## D002 - Use endpoint-aware, windowed M-Team additional-data scheduling

Date: 2026-07-08
Related Requirement: R001

### Decision

Prowlarr's M-Team additional-data enrichment should move from direct per-row MediaInfo calls to a backend scheduler with endpoint-specific requesters, cancellable/expiring handles, and business-side windowed task creation.

The scheduler should maintain three logical queues:

- `mediaInfo` explicit request queue.
- `detail` explicit request queue.
- Search-result additional-data queue.

The `mediaInfo` requester and `detail` requester should each send at most one request every 20 seconds for their own endpoint. They should be endpoint-aware and independent: a rate limit on `/api/torrent/mediaInfo` cools only the MediaInfo requester, and a rate limit on `/api/torrent/detail` cools only the Detail requester. The requesters should be offset when possible, so the two endpoints do not normally fire in the same second.

Both requesters follow the same priority and limit rules:

- The MediaInfo requester first consumes the explicit MediaInfo queue, then the additional-data queue.
- The Detail requester first consumes the explicit Detail queue, then the additional-data queue.
- If either requester sees a M-Team `request too frequent` response, the currently executing task must be returned to the top of its original queue, that endpoint must cool down for 12 minutes, and the task must remain pending rather than failed.
- A task taken from the additional-data queue must be claimed atomically so the two requesters cannot execute the same task at the same time.

Search-result enrichment should use windowed task creation. A business party should not create additional-data tasks for every search result at once. Instead, it should request only the first `x` rows it currently cares about, such as four rows. When one task finishes and returns data, the business party may request the next row. This keeps each business party responsible for only a small active set of handles.

Prowlarr UI, Radarr, and Sonarr should be treated as business parties:

- Prowlarr UI may request and track a small active window for the visible/current result set.
- Radarr and Sonarr should hold Prowlarr handles on their own backend side, not rely on their browser frontends as the only owner.
- Radarr/Sonarr should call Prowlarr cancellation APIs when a manual search session is replaced, closed, abandoned, or expires.
- If a browser refresh or close prevents explicit cancellation, Prowlarr handle leases and TTL cleanup remain the correctness fallback.

Handles should be leases rather than permanent task ownership:

- Prowlarr returns a `handleId` when a business party requests additional data for one result.
- Multiple handles may point at one internal task when different business parties request the same torrent; when the task reaches a terminal result, all still-active handles must be able to observe that same result.
- Status/wait calls should automatically renew the handle lease.
- Renewing any handle must also refresh the task lease so the shared task is not cleaned up while at least one business party is still polling it.
- A default lease such as 5 minutes should be used so abandoned queued work expires naturally.
- Cancellation should be idempotent.
- If every handle for an internal task expires or is canceled while the task is still queued, the queued task should be removed.
- If every handle for an internal task expires or is canceled while the task is running, the running HTTP request is not forcibly aborted, but the task is canceled when the request returns and its result is dropped instead of notifying expired/canceled handles.
- If a rate-limited task is about to be returned to its queue but no active handle still cares about it, it should be dropped instead.
- Handle ids are caller/session state and must not be persisted in shared release caches, otherwise one business party can accidentally receive or renew another party's handle.

Automatic searches in Radarr/Sonarr must preserve their decision semantics. Windowing only limits how many Prowlarr additional-data tasks are active at once; it must not allow Radarr/Sonarr to make a final automatic decision before all candidates whose additional data is required by the decision logic have completed, timed out, or otherwise reached a terminal state.

### Implementation TODO

- Add a Prowlarr backend M-Team additional-data scheduler service with three queues, endpoint-specific requesters, 20-second endpoint spacing, optional endpoint offset, and 12-minute endpoint-specific cooldown.
- Add task models that preserve original queue identity, current endpoint claim, status, active handles, lease expiry, and enough release identifiers to update cached search releases.
- Add M-Team MediaInfo and Detail request wrappers that use the scheduler instead of direct `FetchMediaInfo` style calls for search-result enrichment.
- Add rate-limit detection shared by MediaInfo and Detail wrappers, including HTTP 429 and M-Team HTTP 200 responses whose API message indicates requests are too frequent.
- Replace direct `/api/v1/search/mediaInfo` request execution with a request/status/wait flow backed by scheduler handles.
- Return additional-data handle/status fields from Prowlarr search results only when a business party explicitly requests a row, not for every result at search-response time.
- Add Prowlarr APIs for one-row additional-data request, handle status or wait, lease renewal through status/wait, and idempotent cancellation.
- Keep the frontend/Radarr/Sonarr active window small and configurable in code, with a conservative default such as four active tasks.
- Update Prowlarr UI to request the first window of rows, advance the window as rows finish, and cancel or stop renewing only the currently active handles when a result set is intentionally replaced.
- Update Radarr/Sonarr downstream behavior so their backends own Prowlarr handles, keep only a small active window, renew while waiting, cancel on manual-search abandonment/session expiry, and continue automatic-search waiting until required candidates are completed or terminal.
- Ensure successful MediaInfo/Detail responses still populate cache so later requests for the same torrent can return immediately without queueing.
- Ensure progress counts are based on the active business-party search/session scope, not every possible result returned by the original search.

## D003 - Supersede hard-coded Chinese accessibility rejection with R006 configuration

Date: 2026-07-09
Related Requirement: R001, R006

### Decision

The earlier hard-coded Radarr Chinese accessibility rejection has been superseded by R006 configurable Release Filter Profiles. Radarr should no longer globally reject releases merely because they have neither Chinese audio nor Chinese subtitles.

Chinese accessibility remains available as configurable data:

- Release Filter Profiles can use MediaInfo-backed fields such as audio language, subtitle language, selected audio, selected-audio score, and `hasChineseAudioOrSubtitle`.
- Quality Profiles decide whether a Release Filter Profile applies by binding `ReleaseFilterProfileId`.
- If no Release Filter Profile is bound, Radarr should not reject or wait for releases solely due to Chinese audio/subtitle availability.
- The Chinese media preference evaluator may still provide fallback selected-audio scoring/display fields when no configurable audio preference service is available, but it must not act as an independent global download-decision specification.

### Reason

R006 moved release filtering and audio preference behavior into user-visible Quality Profile bindings. A standalone hard-coded Chinese rule could reject releases even when the user had only created a filter profile and had not attached it to the movie's Quality Profile, which made the configured filter model misleading.

### Consequences

- Chinese access requirements must be represented as Release Filter Profile conditions if the user wants them enforced.
- Interactive and automatic searches should only wait on MediaInfo for Chinese access decisions when the active Quality Profile's bound Release Filter Profile needs those MediaInfo fields.
- Existing release API fields such as `preferredAudioInfo`, `audioPreferenceScore`, and `hasChineseAudioOrSubtitle` can remain available for display, sorting, and future configuration.
