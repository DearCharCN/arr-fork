# Radarr Release Filter and Audio Scoring Design

Status: Draft
Date: 2026-07-09
Related requirements: R001, R002, R003, R005

## Goal

Add a configurable Radarr release decision layer that can:

- Run release filters on the backend, so automatic search and RSS decisions obey the same filter rules as interactive search.
- Score each audio track from its own language/specification text.
- Select one preferred audio track according to a configurable language preference.
- Sort automatic tracking candidates by Custom Format score first, then selected audio score.
- Support mutex groups for audio scoring and Custom Format scoring so equivalent or overlapping matches do not double count.

Weighted all-column sorting is intentionally out of scope for this phase.

## Non-Goals

- Do not implement a general weighted scoring engine yet.
- Do not replace Radarr's existing quality profile system.
- Do not infer precise audio/subtitle availability from release titles when R001 MediaInfo fields are available.
- Do not make frontend-only filters responsible for automatic search decisions.

## Feature Overview

The design introduces four related configuration concepts:

- Backend Release Filter Profile
- Audio Language Mapping
- Audio Score Profile
- Audio Language Preference
- Custom Format Mutex Group

Quality Profiles can reference these settings. A movie using that Quality Profile will apply the configured backend filter, Custom Format mutex groups, audio language preference, and audio scoring profile during release decisions.

## Backend Release Filter Profile

Radarr should implement release filters on the backend instead of relying only on the frontend Custom Filter system.

### Data Model

A filter is stored as a condition tree:

- A group node has:
  - `mode`: `and` or `or`
  - `children`: condition nodes or nested group nodes
- A condition node has:
  - `field`
  - `operator`
  - `value`

This should mirror the nested filter shape introduced for R005, but the backend must have its own evaluator.

### Supported Field Categories

Fields that do not require additional MediaInfo:

- Title
- Indexer
- Protocol
- Quality
- Custom Format score
- Size
- Age
- Seeders
- Peers
- Indexer flags
- Release group

Fields that require R001 MediaInfo:

- Audio languages
- Subtitle languages
- Has specific audio language
- Has specific subtitle language
- Selected audio language
- Selected audio specification
- Selected audio score
- Has Chinese audio or Chinese subtitles
- Additional-data status

### Automatic Search Behavior

If a Quality Profile uses a backend filter and that filter references MediaInfo-backed fields:

1. Radarr gets initial releases.
2. Radarr identifies candidates whose filter outcome depends on pending MediaInfo.
3. Radarr requests additional data through the existing Prowlarr/Radarr R001 enrichment path.
4. Radarr waits until required rows are completed, failed, or timed out.
5. Radarr evaluates the backend filter.
6. Releases that do not pass are rejected with a clear rejection reason.

If MediaInfo is unavailable and a filter condition cannot be evaluated, the default behavior should be to fail the condition and reject the release with a message such as:

`MediaInfo unavailable for backend release filter`

### Interactive Search Behavior

Interactive search should display the same backend filter result. Frontend filtering may still exist for temporary table filtering, but it must not be the only filter used for automatic decisions.

The UI should indicate:

- Pass
- Rejected by backend filter
- Waiting for additional data
- MediaInfo unavailable

## Audio Language Mapping

Radarr should add a user-editable audio language mapping table.

### Purpose

Different releases may label the same language in different ways. For example:

- `Chinese`
- `Mandarin`
- `Guoyu`
- `国语`
- `國語`
- `中文`

These should all be able to map to Radarr's standard `Chinese` language.

### Data Model

Each mapping entry contains:

- `language`: Radarr language id/name, such as `Chinese`
- `aliases`: list of strings or optional regex patterns
- `enabled`: boolean

Example:

```json
{
  "language": "Chinese",
  "aliases": ["Chinese", "Mandarin", "Guoyu", "国语", "國語", "中文", "普通话"]
}
```

### Matching Rules

1. Try user-defined mappings first.
2. If no mapping matches, fall back to default language-name and ISO-code matching.
3. If a track matches a configured language, attach that standard language tag to the track.
4. If the track language matches the movie's original language, also attach the virtual `Origin` tag.

Example:

Movie original language: `English`

Tracks:

- `English TrueHD Atmos 7.1` => `English`, `Origin`
- `Chinese DDP 5.1` => `Chinese`
- `Guoyu DDP 5.1` => `Chinese`

If the movie original language is Chinese, a Chinese track can be both `Chinese` and `Origin`.

## Audio Score Profile

Radarr should add configurable audio track scoring.

### Scope

Audio scoring applies to each individual audio track. It should not score all tracks together. Only the final selected track contributes its score to release sorting.

### Data Model

An Audio Score Profile contains:

- Name
- Enabled score rules
- Enabled audio mutex groups

Each score rule contains:

- Name
- Match type: contains, regex, or normalized contains
- Pattern
- Score
- Optional mutex group
- Enabled flag

### Mutex Groups

An audio mutex group means: if multiple rules in this group match the same audio track, only the highest scoring matched rule contributes.

Example groups:

Channel group:

- `7.1` => +30
- `5.1` => +15

Lossless codec group:

- `TrueHD` => +50
- `DTS-HD MA` => +50

Object audio:

- `Atmos` => +50

Dolby lossy group:

- `DDP` => +15
- `DD` => +10

Open question: TrueHD/DTS-HD MA and DDP/DD can either be separate groups or a single codec-class mutex group. A single codec-class group avoids double counting when one audio specification contains both a lossless primary codec and a compatibility/core codec.

### Scoring Algorithm

For one audio track:

1. Normalize its language/specification text.
2. Run all enabled score rules.
3. Add all non-mutex matched scores.
4. For each mutex group, add only the highest matched score in that group.
5. Store the result as the track score.

Example:

`English TrueHD Atmos 7.1`

- TrueHD +50
- Atmos +50
- 7.1 +30
- Total: 130

`Chinese DDP 5.1`

- DDP +15
- 5.1 +15
- Total: 30

## Audio Language Preference

Radarr should add configurable preferred audio selection.

### Purpose

Different users may want different language priorities:

- User A: `Chinese`, then `Origin`
- User B: `Japanese`, then `English`, then `Origin`
- User C: `English` only

### Data Model

An Audio Language Preference contains:

- Name
- Ordered preference entries
- Score gap threshold
- Referenced Audio Score Profile

Each preference entry contains:

- Language tag: standard language or virtual `Origin`
- Enabled flag

### Selection Algorithm

1. Apply audio language mappings to every audio track.
2. Apply the virtual `Origin` tag when a track matches the movie original language.
3. Score every audio track using the selected Audio Score Profile.
4. For each language preference entry, find the highest scoring track matching that language/tag.
5. Start with the first preference entry that has a matching track.
6. Compare it against later preference entries.
7. If a later preference's best track exceeds the current selected track by more than the configured score gap threshold, switch to the later track.
8. The chosen track becomes the release's selected audio track.
9. The chosen track's score becomes the release's `audioScore`.

Example:

Preference:

- `Chinese`
- `Origin`
- score gap threshold: 80

Movie original language: English

Tracks:

- `English TrueHD Atmos 7.1` => 130, tags `English`, `Origin`
- `Chinese DDP 5.1` => 30, tags `Chinese`
- `Guoyu DDP 5.1` => 30, tags `Chinese`

Result:

- Chinese best score: 30
- Origin best score: 130
- Difference: 100
- 100 > 80, so select `Origin English TrueHD Atmos 7.1`
- Release audio score: 130

If the threshold were 120, Radarr would keep the Chinese track because the Origin track does not exceed Chinese by more than 120.

### Release API Fields

Radarr release resources should expose:

- `audioScore`
- `selectedAudioInfo`
- `selectedAudioLanguage`
- `selectedAudioTags`
- `audioScoreBreakdown`
- `audioLanguagePreferenceName`

Interactive search should show an `Audio Score` column and a compact explanation popover.

## Custom Format Mutex Groups

Radarr should extend Custom Format scoring with optional mutex groups.

### Purpose

When multiple Custom Formats represent mutually exclusive or overlapping concepts, only the highest scoring match should count.

Examples:

- DoVi vs HDR10 vs HDR10+
- Multiple release-source tiers
- Multiple audio/video descriptor formats that overlap in titles

### Data Model

A Custom Format Mutex Group contains:

- Name
- List of Custom Format ids
- Enabled flag

Quality Profiles can select which Custom Format mutex groups are active.

### Scoring Algorithm

When calculating Custom Format score for a Quality Profile:

1. Calculate matched Custom Formats as Radarr already does.
2. Add scores for matched Custom Formats not in any active mutex group.
3. For each active mutex group, find matched Custom Formats in the group.
4. Add only the highest score from that group.
5. Store a score breakdown for explanation.

Existing Quality Profiles should behave the same until they enable mutex groups.

## Quality Profile Integration

Each Quality Profile should be able to reference:

- Backend Release Filter Profile
- Enabled Custom Format Mutex Groups
- Audio Language Preference
- Audio Score Profile
- Enabled Audio Mutex Groups, if not already included in the Audio Score Profile

Default values must preserve current Radarr behavior:

- No backend release filter
- No Custom Format mutex groups
- No audio preference scoring, unless explicitly enabled

## Release Decision Order

For this phase, automatic tracking sorting should be:

1. Custom Format score
2. Audio score
3. Existing Radarr tie-breakers

The exact relationship with quality should follow the chosen Quality Profile strategy from R003:

- Existing behavior remains default.
- If the Quality Profile enables Custom Format score priority, Custom Format score can sort before quality according to that strategy.
- Audio score is applied after Custom Format score.

## Rejection Reasons and Explanations

Radarr should add clear reasons for rejected or delayed releases:

- `ReleaseFilterRejected`
- `ReleaseFilterMediaInfoPending`
- `ReleaseFilterMediaInfoUnavailable`
- `AudioPreferenceNoMatchingTrack`

Interactive search should expose explanation details:

- Filter pass/fail reason
- Matched audio language aliases
- Selected audio track
- Audio score breakdown
- Custom Format mutex score breakdown

## Implementation Phases

### Phase 1: Backend Filter Foundation

- Add backend release filter models.
- Add filter evaluator.
- Add Quality Profile reference to a backend filter.
- Support non-MediaInfo fields first.
- Add rejection reasons.

### Phase 2: MediaInfo-Aware Backend Filters

- Mark filter fields that require R001 MediaInfo.
- Integrate with existing Radarr/Prowlarr additional-data waiting.
- Evaluate audio/subtitle filter fields after MediaInfo is complete.

### Phase 3: Audio Language Mapping and Track Tagging

- Add audio language mapping settings.
- Implement alias matching.
- Add virtual `Origin` tag.
- Expose tagged tracks in release API/debug output.

### Phase 4: Audio Score Profiles

- Add audio score rule model.
- Add audio mutex groups.
- Score every audio track.
- Add score breakdown.

### Phase 5: Audio Language Preference

- Add preference ordering.
- Add score gap threshold.
- Select one preferred audio track.
- Expose `audioScore` and selected track fields.

### Phase 6: Custom Format Mutex Groups

- Add Custom Format mutex group settings.
- Integrate with Quality Profile Custom Format score calculation.
- Preserve existing score behavior by default.

### Phase 7: Sorting and UI

- Sort by Custom Format score, then audio score.
- Add interactive search columns:
  - Audio Score
  - Selected Audio
  - Backend Filter result
- Add explanation popovers.

## Acceptance Criteria

- A user can map `Guoyu`, `Mandarin`, and `Chinese` to standard `Chinese`.
- A track matching the movie original language gets the `Origin` tag.
- A user can configure audio language preference order, such as `Chinese` then `Origin`.
- A user can configure a score gap threshold that allows a much better fallback language track to override the preferred language.
- Each audio track is scored independently.
- Audio mutex groups prevent double counting within the same group.
- Only the selected audio track contributes to the release audio score.
- Custom Format mutex groups allow only the highest matched Custom Format score in each enabled group.
- A Quality Profile can select a backend release filter, Custom Format mutex groups, audio language preference, and audio scoring profile.
- Automatic search and RSS decisions run backend filters, not just frontend table filters.
- If a backend filter needs MediaInfo, automatic decisions wait for additional data before final rejection/approval.
- Automatic release sorting uses Custom Format score first and audio score second for this phase.
