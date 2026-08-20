# Task 74 — Add Healthchecks and backup status to Glance Hosting

## Objective

Add a compact Hosting dashboard section for backup freshness and Healthchecks
project status without exposing ping UUIDs, repository paths, backup target names,
or raw failure payloads.

## Background

The Hosting page now shows core monitors and Beszel fleet summary. The next most
useful operational signal is whether scheduled jobs and backups are healthy. This
is popular for home dashboards because it answers the daily question: "Can I
recover if something breaks?"

## Current Behavior

- Hosting shows service reachability and Beszel host labels/status.
- Healthchecks is only a monitor link/check.
- Backup state is visible through CLI/reporting, not Glance.
- `config/glance.env.example` reserves `GLANCE_HEALTHCHECKS_URL` and
  `GLANCE_HEALTHCHECKS_API_KEY`, but no widget consumes them yet.

## Desired Behavior

Glance shows a bounded summary such as checks up/down/paused, last backup age,
and a clear stale/unknown state. It must never render ping URLs, UUIDs, raw target
paths, restic repository names, hostnames beyond approved labels, or secrets.

## Implementation Plan

1. Review Healthchecks API support for a read-only project key and identify a
   safe summary endpoint.
2. Decide whether backup freshness can come from existing generated state/report
   files or needs a tiny local read-only adapter. Do not parse restic repositories
   directly from Glance.
3. Freeze allowed fields in `docs/glance-capability-matrix.md`.
4. Implement one Hosting widget with conservative cache and safe failures.
5. Document credential setup in `docs/services/glance.md` and
   `docs/reference/secrets.md` if new handling is needed.
6. Validate unauthorized, unavailable, empty, stale, and degraded states.

## Affected Files

- `compose/monitoring/glance/pages/hosting.yml`
- possible local adapter only if explicitly justified
- `config/glance.env.example`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

## Testing Plan

- Run shell/YAML/Glance validation and Compose rendering.
- Test live API using key presence only; do not print raw response payloads.
- Confirm no ping UUIDs, target names, repo URLs, or secrets appear in HTML/logs.
- Capture sanitized desktop/mobile screenshots.

## Rollback

Revert the widget/adapter commit and deploy normally. Do not delete or rotate the
Healthchecks key unless the operator explicitly requests it.

## Dependencies

- Healthchecks read-only API key.
- A reviewed backup status source that does not require destructive or expensive
  repository operations.

## Risks

Healthchecks can expose private job names and ping URLs. Backup state can expose
repository layout and target names. Keep summaries aggregate and labels approved.

## Complexity

Medium.

## Suggested Order

Do this after the current Hosting/Beszel page remains stable for a few days.

## Decisions and Rejected Alternatives

- Decision: Healthchecks and backup status belong on Hosting, not Home.
- Decision: summary-only display is enough for daily use.
- Rejected: rendering raw Healthchecks check lists by default because names/UUIDs
  may reveal operational details.
- Rejected: calling restic from Glance because it is too powerful and slow for a
  dashboard widget.
