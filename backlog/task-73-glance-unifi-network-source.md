# Task 73 — Review and implement UniFi as the primary deep Network source

## Objective

Add UniFi as the primary deep Network source for the Glance Network page, but
only after the live controller, read-only credential model, and safe API path are
verified. This is the operator-selected primary source for task 56; AdGuard is the
secondary source and must remain a separate implementation.

## Background

Task 56 allows exactly one deep Network source family at a time. The operator
selected both UniFi and AdGuard, with UniFi first. The current repository has
Homepage-oriented UniFi notes, but Glance `v0.8.5` has no native UniFi widget.
The existing capability matrix still marks UniFi as `Needs service` because the
controller/API is not audited for Glance. On 2026-08-20, the operator approved
direct UniFi API-key access for Glance, provided the key is read-only and used
only for monitoring.

## Why This Exists

Implementing UniFi directly from Glance without a verified API would risk
inventing endpoints, reusing overly broad credentials, or exposing topology and
client identity. The safe next step is a focused source review that either proves
a direct `custom-api` path or authorizes a small local adapter in a later task.

## Current Behavior

- The Network page shows Speedtest Tracker and compact network-adjacent
  reachability checks.
- Homepage documentation references UniFi widget variables, but those variables
  are Homepage-only and must not be reused by Glance.
- `config/glance.env.example` reserves `GLANCE_UNIFI_URL`,
  `GLANCE_UNIFI_API_KEY`, `GLANCE_UNIFI_API_HEADER`, and
  `GLANCE_UNIFI_API_PATH` for a dedicated read-only direct API key path. The
  operator reports a UCG Fiber gateway/controller and will populate the real URL
  and API key only in `/etc/domum-core/secrets/glance.env`.
- `docs/glance-capability-matrix.md` marks `UniFi counts/health` as
  `Needs service`.

## Desired Behavior

Glance shows only bounded UniFi aggregates such as WAN health, client counts, AP
or switch health counts, and controller freshness. It must not expose topology,
client names, MAC addresses, IP addresses, SSIDs, or device aliases unless a
future matrix update explicitly approves each field.

## Implementation Plan

1. On the Pi, populate `GLANCE_UNIFI_URL` with the UCG Fiber
   gateway/controller URL reachable from Glance, then identify the live
   controller version and supported API authentication mode without printing
   credentials or private topology.
2. Create a dedicated Glance read-only UniFi API key and place it in
   `GLANCE_UNIFI_API_KEY`. Do not reuse Homepage
   credentials or an admin account. The key must not have write/admin privileges.
3. Verify whether Glance `custom-api` can call one documented endpoint directly
   using `GLANCE_UNIFI_API_HEADER` and `GLANCE_UNIFI_API_PATH`. If cookie/CSRF
   login chaining is required, reject direct Glance config and propose a small
   local adapter as a new task.
4. Freeze the approved fields in `docs/glance-capability-matrix.md` before
   rendering anything.
5. Implement one compact widget on `compose/monitoring/glance/pages/network.yml`
   with 5m cache, safe failure behavior, and no raw payload details.
6. Document credential names/scopes in `docs/reference/secrets.md` and operator
   setup/validation in `docs/services/glance.md`.
7. Test unauthorized, unavailable, stale, empty, partial, and rate-limited
   responses. Confirm no client/topology identifiers appear in Git, logs, URLs,
   or screenshots.

## Affected Files

- `compose/monitoring/glance/pages/network.yml`
- possible approved adapter under `compose/monitoring/` only if direct API is
  rejected and a later implementation task authorizes it
- `config/glance.env.example`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

Do not modify UniFi controller state, DNS, firewall, Traefik policy, Homepage, or
source networks.

## Testing Plan

- Run repository shell/YAML/Glance validation and Compose rendering.
- Validate against the live UniFi UI/API at matching times without capturing raw
  private payloads.
- Test invalid credential, unreachable controller, stale data, empty site, and
  partial field responses.
- Inspect Glance logs for errors and accidental sensitive output.
- Capture sanitized responsive screenshots after deployment.

## Rollback

Revert the UniFi commit, deploy through `sudo domum-core update`, then run a
supervised full-stack `sudo domum-core apply` and `sudo domum-core checkup`. Do
not delete or rotate the UniFi credential during rollback unless the operator
explicitly chooses to revoke it.

## Dependencies

- Task 55 Pi validation and approval.
- Operator-approved UniFi as the primary deep Network source.
- Operator-approved direct UniFi API key access, read-only and monitoring-only.
- A verified least-privilege UniFi API endpoint and schema for the live
  controller/version.
- If direct Glance `custom-api` is not enough, a separate adapter task must be
  approved before implementation.

## Risks

UniFi data can reveal topology, family presence, SSIDs, client identities, MAC
addresses, and internal IPs. Keep the widget aggregate-only, cache results, use a
dedicated read-only credential, and render unknown on failure.

## Complexity

Small-medium if a direct API-key endpoint exists; medium if a local adapter is
required.

## Suggested Order

Work this before any additional Network source. AdGuard remains the secondary
source and should be implemented separately only after this blocker is recorded.

## Decisions and Rejected Alternatives

- Decision: UniFi is the primary deep Network source, selected by the operator.
- Decision: direct UniFi API-key access is approved for Glance if the key is
  read-only and used only for monitoring.
- Decision: AdGuard is secondary and stays in a separate commit/task path.
- Rejected: Reuse Homepage UniFi variables, because Homepage env is not mounted
  into Glance and credential scope/ownership differ.
- Rejected: Invent UniFi API URLs from memory, because unsupported endpoints can
  break silently or expose private topology.
- Rejected: Render client, topology, SSID, MAC, IP, or device-name details by
  default, because they are private-personal/private-topology data.
