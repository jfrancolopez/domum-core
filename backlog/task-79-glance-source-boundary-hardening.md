# Task 79 — Harden Glance source and secret boundaries

## Objective

Close the remaining source-boundary risks found during the Glance task-63 static
privacy audit without weakening the LAN/Tailscale access policy, exposing source
credentials, or adding broad host access to the dashboard.

## Background

The current Glance pages use reviewed, bounded summaries for Speedtest Tracker,
AdGuard, UniFi, and Beszel. The task-63 audit found four residual design risks:

- Glance receives the complete `/etc/domum-core/secrets/glance.env`, including
  reserved future calendar, Home Assistant, media, Steam, Twitch, Spotify, and
  YouTube credentials if an operator fills them in.
- The UniFi custom API request uses `allow-insecure: true` because the controller
  certificate is not valid for the LAN address. The request carries a monitoring
  API key.
- The Beszel adapter is unauthenticated on the shared `domum-proxy` network and
  authenticates to Beszel over plain HTTP.
- RSS image URLs are supplied by external feeds without a repository-controlled
  origin policy.

These are boundary issues, not reasons to add more dashboard data. The current
public-safe and aggregate widgets must remain stable while the boundaries are
made narrower.

## Current Behavior

- `compose/monitoring/glance.yml` loads all of `glance.env` into Glance.
- The UniFi widget sends `${GLANCE_UNIFI_API_KEY}` with `allow-insecure: true`.
- `glance-beszel-adapter` listens on `domum-proxy` without endpoint
  authentication and reaches `beszel:8090` over HTTP.
- Native RSS widgets can render feed-provided thumbnails from their source URLs.
- AdGuard aggregate stats use a username/password web account because a narrower
  account role has not been verified for the installed version.

## Desired Behavior

- Each container receives only the secrets required for its active source.
- UniFi API credentials are sent only over a connection whose certificate is
  verified, or through a separately approved local trust mechanism. Do not solve
  this by silently switching the API key to cleartext HTTP.
- The Beszel adapter is reachable only by Glance and its Beszel dependency, with
  a narrowly scoped authenticated or network-isolated endpoint and encrypted
  upstream transport where supported.
- Feed images are disabled, self-hosted, or restricted to an explicitly reviewed
  origin policy; a compromised feed must not make the browser request arbitrary
  image hosts by default.
- AdGuard access uses a dedicated least-privilege account or an approved
  aggregate-only API mechanism.

## Implementation Plan

1. Inventory the exact variables consumed by current Glance widgets versus
   reserved future variables. Select the smallest secret-plumbing design that
   does not expose future credentials to Glance. Prefer existing Docker secrets or
   file-backed `readFileFromEnv` support over a new dependency.
2. Verify the live UniFi certificate and endpoint options on the Pi without
   recording private values. Implement a trusted CA path or approved hostname
   route, then remove `allow-insecure: true` and test invalid, expired, and valid
   certificate behavior.
3. Design the smallest adapter network boundary. Keep Beszel and the adapter on
   a private network, expose `/summary` only to Glance, and use HTTPS upstream if
   the live Beszel endpoint supports it. Add endpoint authentication only if
   network isolation alone cannot prove the caller boundary.
4. Verify AdGuard account roles and replace the operator-account fallback if the
   installed version supports a dedicated aggregate/read-only role. Do not print
   or record credentials.
5. Decide whether the accepted RSS policy is no thumbnails or an explicit static
   allowlist. Prefer no thumbnails if Glance v0.8.5 cannot enforce an origin
   allowlist without a new proxy.
6. Add failure tests and sanitized documentation for each boundary, including
   unauthorized requests, certificate failures, missing secrets, and changed feed
   image origins.
7. Update the capability matrix and task-63 audit, then mark this task complete
   only after Pi evidence and operator approval are recorded.

## Affected Files

- `compose/monitoring/glance.yml`
- `compose/monitoring/glance-beszel-adapter.yml`
- `compose/monitoring/glance-beszel-adapter/`
- `compose/monitoring/glance/pages/network.yml`
- RSS page files under `compose/monitoring/glance/pages/`
- `config/glance.env.example`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `docs/glance-capability-matrix.md`
- `docs/glance-dashboard-audit.md`
- `backlog/README.md`

## Testing Plan

- Run shellcheck, YAML lint, Compose rendering, Glance v0.8.5 validation,
  adapter tests, catalog consistency, and tracked-file gitleaks checks.
- On the Pi, inspect container mounts, networks, environment-variable names, and
  request paths without printing secret values.
- Verify Glance cannot read reserved future secret values and the adapter cannot
  be reached from an unrelated container.
- Test UniFi with valid trusted TLS, invalid certificate, unavailable endpoint,
  and missing key states.
- Test Beszel adapter unauthorized/unreachable/stale responses and confirm no
  token or source payload appears in Glance HTML or logs.
- Test RSS image behavior with an approved source and a changed/unapproved image
  origin.

## Rollback

Revert only the hardening commit after reviewing the diff, then restore the last
known-good Glance and adapter configuration through the normal update/apply path.
Do not delete, rotate, or rewrite secret files during rollback. If a credential
was exposed, stop and ask the operator to rotate it.

## Dependencies

- Production Pi access for live certificate, network, and service verification.
- Operator approval of the UniFi certificate/hostname and AdGuard account path.
- A Glance-v0.8.5-compatible secret/file mechanism and Docker network design.
- No new external dependency unless separately approved in writing.

## Risks

Changing secret plumbing or networks can make an otherwise healthy dashboard
blank. Removing TLS bypass without a verified certificate path can break UniFi
summaries. Disabling thumbnails changes the visual design but is safer than
allowing arbitrary browser requests. Network isolation may require coordinated
Compose changes for Beszel.

## Complexity

Medium-high.

## Suggested Order

Do this after the current task-63 YAML/template corrections and before adding any
new private-personal integration. Start with secret isolation, then UniFi TLS,
then adapter networking, AdGuard scope, and RSS image policy.

## Decisions and Rejected Alternatives

- Decision: keep current aggregate fields and source limits while hardening the
  transport and credential boundaries.
- Decision: do not expose the host backup heartbeat to Glance; use a reviewed
  summary source or separately approved exporter instead.
- Rejected: retaining `allow-insecure: true` as a permanent exception because the
  request carries a credential.
- Rejected: switching UniFi to cleartext HTTP as a shortcut because it exposes the
  API key on the network.
- Rejected: mounting the host filesystem or Docker socket into Glance to avoid an
  adapter/network decision.
- Rejected: adding a thumbnail proxy or new dependency before proving that a
  no-thumbnail policy is insufficient.
