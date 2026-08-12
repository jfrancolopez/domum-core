# Task 57 — Build the core Glance Media page

## Objective

Build a private, media-rich activity and discovery page from the exact media
services found in task 47. Begin with one playback source and one library/release
source; add no placeholder integrations for absent services.

## Background

Possible services include Plex, Jellyfin, Tautulli, Immich, Sonarr, Radarr,
Lidarr, Readarr, Bazarr, Prowlarr, Overseerr/Jellyseerr, Audiobookshelf,
Navidrome, qBittorrent/Transmission, SABnzbd/NZBGet, mostly expected on
domum-core-media or other hosts. The operator chose inventory-before-design and
has not yet granted blanket permission to show titles, users, or activity.

Community widgets exist for several services, but each must pass the immutable
source/security review in the program charter. Extension containers are rejected
by default. Glance must not become a media control plane.

## Current Behavior

There is no Media page and no media credential plumbing in Glance. Exact active
services, APIs, privacy choices, and data schemas are audit outputs.

## Desired Behavior

Core Media provides useful now-playing/progress context, recent/upcoming library
information, bounded imagery, and links to source applications. Additional
photo/audio/download/storage sources belong to task 58.

## Implementation Plan

1. Re-read Media matrix rows and stop unless exact source hosts, API versions,
   read-only credential scopes, and title/user/poster privacy are resolved.
2. Select the smallest useful first slice: one of Plex/Jellyfin/Tautulli for
   playback plus one of Sonarr/Radarr or the confirmed library manager for
   upcoming/recent content. Explain the selection in the matrix.
3. Audit candidate community templates completely: immutable commit, endpoints,
   headers, HTML escaping, external images, caching, pagination, rate limits,
   maintenance, and license. Copy only reviewed templates into Git.
4. Implement active streams/now playing with approved fields such as progress,
   device, bitrate, and direct-play/transcode. Sort only from real structured
   values. Do not add playback controls.
5. Add bounded recently watched/added and upcoming/release lists from confirmed
   APIs. Separate missing/grabbed data from availability and label timestamps.
6. Defer trending/discovery, Immich, audio/music, download clients, and storage
   summaries to task 58 even if their rows are `Ready`.
7. Limit posters, dimensions, item counts, and cache durations. Lazy behavior
   must be verified, not assumed. Avoid large main-page iframes.
8. Test no streams, multiple streams, missing poster, Unicode/HTML titles,
   unauthorized API, timeout, stale data, and partial payloads.
9. Update matrix/provenance/docs and obtain approval before task 58.

## Affected Files

- `compose/monitoring/glance/pages/media.yml`
- approved templates under `compose/monitoring/glance/widgets/media/`
- approved local CSS/assets only
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` for variable/file names and scopes only
- `backlog/README.md` (status only)

Do not modify any media application, database, storage, network, authentication,
download client, Homepage file, or media data.

## Testing Plan

- Run all repository, Compose, Glance, YAML, and gitleaks checks.
- Compare every displayed field against live source data without recording
  private payloads.
- Test all enumerated empty/error/escaping cases and ensure templates cannot
  inject unsafe title/user content.
- Verify sensitive titles/users/activity are absent from Git, logs, screenshots,
  and browser URLs where prohibited.
- Test target widths and poster/image failure without overflow.
- Measure image bytes, request count, load time, CPU, and RAM against Network.

## Rollback

Revert the core Media commit, update the checkout, then run a supervised
full-stack apply and checkup after inspecting update candidates. Do not revoke,
delete, rotate, or overwrite source credentials during rollback.

## Dependencies

Requires approved task 56, private access proof, and resolved core Media rows.
Any extension, adapter, or source change requires a new approved task.

## Risks

Media activity is personal data. Posters can dominate bandwidth and external
image requests can leak viewing interests. Strict privacy, escaping, limits,
and caching are mandatory.

## Complexity

Medium due to the intentionally small first slice; medium privacy risk.

## Suggested Order

Phase 4. Land the smallest playback/library slice before task 58.
