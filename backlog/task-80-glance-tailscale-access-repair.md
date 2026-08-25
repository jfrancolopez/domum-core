# Task 80 — Repair Tailscale Glance access convergence

## Objective

Ensure the repository's host initialization and checkup logic keeps Docker's
`userland-proxy=false` requirement true when the Glance Traefik allowlist must see
real Tailscale client addresses.

## Background

The operator reported HTTP Forbidden from a Tailscale client while LAN access was
expected to remain trusted. The Glance middleware allows the Tailscale CGNAT range
`100.64.0.0/10`, but Docker can hide that source behind its userland proxy. The
current `bin/domum-core` compared `/etc/docker/daemon.json` to an exact small JSON
document and left any file with additional valid settings unchanged, even when
`userland-proxy` was missing or true.

## Current Behavior

- `domum-core init` creates the exact daemon file when absent.
- If a valid daemon file contains extra operator settings, init now offers to
  preserve them while setting `userland-proxy=false`.
- `domum-core checkup` reports only the exact log-limit document status and does
  not independently report whether the running Docker daemon has reloaded the
  userland-proxy requirement.
- The Glance Traefik allowlist itself correctly includes the configured LAN CIDR
  and `100.64.0.0/10`.
- A Tailscale client can still receive `403` if the dashboard hostname resolves
  to the public/WAN address instead of the Pi's Tailscale address. Tailscale
  connectivity alone does not force public DNS traffic onto the tailnet.

## Desired Behavior

- Initialization preserves existing valid Docker daemon settings while setting
  `userland-proxy` to boolean `false`.
- A live Docker daemon restart is explicitly confirmed, never silently performed.
- Checkup reports userland-proxy status separately from log-limit drift.
- Invalid JSON is never overwritten automatically.

## Implementation Plan

1. Done in `bin/domum-core`: add a jq-backed boolean check and merge
   `userland-proxy=false` into valid existing daemon JSON without deleting other
   keys.
2. Done in `bin/domum-core`: prompt before restarting Docker after a live setting
   change and report the manual restart command when declined.
3. Done in `bin/domum-core`: add an independent checkup warning/action for the
   userland-proxy requirement and detect when `daemon.json` is newer than the
   running Docker daemon.
4. On the Pi, run read-only inspection first, then `sudo domum-core init` during a
   maintenance window if the setting is missing/true. Re-test Tailscale, LAN, and
   external Glance paths.
5. Test the dashboard hostname both normally and with a temporary client-side
   `curl --resolve` mapping to the Pi's Tailscale IP. If only the mapped request
   succeeds, use approved split DNS or equivalent routing; do not widen the
   allowlist.
6. Record sanitized results in `docs/glance-dashboard-audit.md` and update task
   49 status only after the real Tailscale request returns HTTP 200.

## Affected Files

- `bin/domum-core`
- `docs/services/glance.md`
- `docs/glance-dashboard-audit.md`
- `backlog/README.md`

## Testing Plan

- Run `bash -n`, Shellcheck, YAML lint, Compose rendering, Glance validation,
  adapter tests, catalog consistency, boundary smoke, and gitleaks.
- Static-test the new jq expressions against valid object JSON, valid JSON with
  extra keys, missing userland-proxy, true userland-proxy, and invalid JSON without
  touching `/etc/docker/daemon.json` in the repository checkout.
- On the Pi, inspect only daemon setting names/booleans and Docker state before
  any restart. After a supervised init/restart, test real LAN, Tailscale, and
  external paths without recording addresses or private dashboard content.

## Rollback

Revert the repository commit, then inspect `/etc/docker/daemon.json` before any
manual rollback. Never replace the live daemon file with a repository fixture or
delete unrelated Docker settings. A Docker restart may be required to restore a
previous daemon setting.

## Dependencies

- Production Pi maintenance window for the restart and path validation.
- Existing `jq` host package installed by `domum-core init`.
- Task 49's approved Traefik IP allowlist remains unchanged.

## Risks

Docker restart interrupts all containers. A malformed daemon file must not be
rewritten automatically. A Tailscale request can remain denied if the router's
observed source is not the expected CGNAT range, if public DNS bypasses the
tailnet, or if another proxy path is used.

## Complexity

Small-medium.

## Suggested Order

Run after the repository fix is pushed and before accepting Tailscale Glance
access. Do not change the Glance middleware ranges while this path is unresolved.

## Decisions and Rejected Alternatives

- Decision: preserve unrelated daemon settings and change only the required
  `userland-proxy` boolean.
- Decision: prompt before a Docker restart because the host runs production home
  automation services.
- Rejected: replacing all of `/etc/docker/daemon.json` with the small repository
  fixture, because that can discard operator settings.
- Rejected: adding a Tailscale `/32` or trusting forwarded headers, because that
  would weaken the real-client-source boundary.
