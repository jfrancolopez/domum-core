# Task 10 — Pin critical stateful images via config vars  [shared-philosophy]

## Objective
Adopt the sibling repo's image-pinning convention for the services where a
surprise major upgrade can destroy data or require migration: MariaDB and
Home Assistant first; optionally Zigbee2MQTT and Z-Wave JS UI.

## Files involved
- `compose/automation/mariadb.yml`, `compose/automation/home-assistant.yml`
  (and optionally `zigbee2mqtt.yml`, `zwave-js-ui.yml`)
- `bin/domum-core` — `export_env_for_compose()`
- `config/domum.conf.example`
- `docs/operations/updates.md`

## Reason
Every compose file in this repo uses a moving tag (`mariadb:latest`,
`home-assistant:stable`, etc.). The sibling repo interpolates
`image: ${SERVICE_IMAGE}` from config, so the operator decides when a
version changes and git records it. For MariaDB specifically, `:latest`
means an unplanned major-version jump (with on-disk format migration) can
happen on any pull+apply — the single riskiest update on this host, and the
recorder DB is what backs HA history.

Deliberately **not** pinning everything: for low-state services (traefik
config is in git, adguard config is a bind mount) `:latest` + the delay
window is acceptable and keeps maintenance burden near zero. Start with the
two that can genuinely hurt.

**Amendment (2026-07-09 audit):** treat Traefik as a third candidate — but
pin the **major only** (`image: ${TRAEFIK_IMAGE:-traefik:v3}`), not a full
version. Traefik is the one service where `:latest` +
`TRAEFIK_AUTO_UPDATE=1` + a 1-day delay means a future v3→v4
static-config break could take down ingress for *every* service overnight.
A major pin keeps auto-updates flowing within v3 while making a major bump
an explicit config edit. Zero added maintenance until a new major releases.

## Implementation plan
1. In `compose/automation/mariadb.yml`:
   `image: ${MARIADB_IMAGE:-mariadb:11.4}` (choose the currently-running
   major.minor — check with `docker inspect` on the host first; never pin to
   something newer than what runs).
2. Same pattern for HA: `image: ${HOMEASSISTANT_IMAGE:-ghcr.io/home-assistant/home-assistant:stable}`
   — pin to a monthly version (`:2026.6`) if the operator wants; the default
   keeps current behavior.
3. Export both vars in `export_env_for_compose()` (empty-safe defaults) and
   add commented entries to `config/domum.conf.example` under a new
   "Image pinning" section explaining the trade-off.
4. Update `docs/operations/updates.md`: how to bump a pinned version
   (edit conf → `updates check` → `apply`), and that pinned services ignore
   `updates apply` until the pin moves.
5. Confirm `updates_check` behaves sanely for a pinned tag (pull of a fixed
   tag is a no-op unless the tag is re-pushed — acceptable).

## Testing plan
- CI compose-validate renders with defaults (no env needed).
- On host: `docker compose ... config | grep image:` shows the same image
  currently running (zero-diff deploy); `sudo domum-core apply` recreates
  nothing.

## Risk
Medium: a wrong pin (older or newer than running) triggers an unplanned
MariaDB up/downgrade on next apply. Mitigation: read the running version
first; zero-diff is the acceptance criterion.

## Rollback
Revert compose + conf changes; `apply` (image ref returns to `:latest`,
which still resolves to the running image until the next pull).

## Dependencies
Task 09 recommended first (its warning makes pin bumps observable).

## Estimated complexity / token size
Medium (~12k tokens).

## Suggested order
10.
