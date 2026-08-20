# Task 75 — Add private calendar and presence intelligence to Glance Home

## Objective

Add useful family-aware Home signals such as upcoming calendar events and named
presence summaries after credential, privacy, and source behavior are reviewed.

## Background

The operator wants the dashboard to be personal, not anonymous. Home is now a
safe public/private shell with weather, clocks, search, and service status, but it
does not yet answer who is home, who may be away, or what is coming up today.

## Current Behavior

- Home has a daily command-center hero, action tiles, weather, clocks, calendar
  month view, service heartbeat, releases, RSS, and bookmarks.
- It has no private calendar event feed.
- It has no Home Assistant or UniFi presence summary.
- `config/glance.env.example` reserves ICS calendar, Home Assistant token, and
  explicit presence allowlist variables, but no widget consumes them yet.

## Desired Behavior

Home shows a small, family-friendly summary: upcoming events from a read-only
calendar, selected named people/home-away states, and safe unknown/stale states.
It must not expose full personal calendars, raw device names, MAC/IP addresses,
SSIDs, or unapproved person/entity names.

## Implementation Plan

1. Done: choose the calendar source. Use a secret read-only ICS URL first; CalDAV
   or Google API only if ICS is insufficient.
2. Done: choose the presence source. Use Home Assistant `person.*` entities, not
   UniFi client/device data.
3. Done: scaffold allowlist variables in `config/glance.env.example`. The future
   adapter must use display names/entities from `GLANCE_PRESENCE_PERSON_N_*` and
   must not infer names from device inventories.
4. Freeze allowed fields in `docs/glance-capability-matrix.md`.
5. Implement one or two compact Home widgets with stale/unknown handling.
6. Document how to rotate calendar URLs and tokens.

## Affected Files

- `compose/monitoring/glance/pages/home.yml`
- possible local read-only adapter if Glance cannot safely parse/auth the source
- `config/glance.env.example`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

## Testing Plan

- Run shell/YAML/Glance validation and Compose rendering.
- Test empty calendar, all-day events, timezone boundaries, expired/rotated ICS
  URL, unavailable Home Assistant, and stale presence.
- Confirm screenshots and logs do not reveal event details beyond approved output.

## Rollback

Revert the widget/adapter commit and deploy normally. Rotate the ICS URL only if
it was exposed in logs, screenshots, or git.

## Dependencies

- Operator-approved calendar source.
- Operator-approved names/entities for presence.
- Private Glance access boundary must remain enforced before rendering personal
  data.
- Live root-only values for `GLANCE_CALENDAR_ICS_URL`,
  `GLANCE_HOMEASSISTANT_TOKEN`, and each approved `person.*` entity.

## Risks

Calendar and presence data are private-personal and can reveal family routines.
Use explicit allowlists, short caches, and conservative summaries.

## Complexity

Medium.

## Suggested Order

Do this before adding more niche pages because it increases daily usefulness.

## Decisions and Rejected Alternatives

- Decision: named presence is allowed only from an operator-approved allowlist.
- Decision: ICS is preferred over broad Google/CalDAV API access.
- Decision: Home Assistant `person.*` is the approved presence source for the
  first implementation.
- Decision: scaffold only for now; do not implement the adapter/widget until live
  ICS URL, token, and entity allowlist values are provided in root-only secrets.
- Rejected: deriving people from UniFi client names because it can expose devices
  and topology.
- Rejected: showing full event descriptions/locations by default.
