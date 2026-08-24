# Task 79 — Harden Glance source and secret boundaries

## Objective

Close the remaining source-boundary risks found during the Glance task-63 static
privacy audit without weakening the LAN/Tailscale access policy, exposing source
credentials, or adding broad host access to the dashboard.

## Background

The current Glance pages use reviewed, bounded summaries for Speedtest Tracker,
AdGuard, UniFi, and Beszel. The task-63 audit found four residual design risks:

- Glance previously received the complete `/etc/domum-core/secrets/glance.env`,
  including reserved future calendar, Home Assistant, media, Steam, Twitch,
  Spotify, and YouTube credentials if an operator filled them in.
- The UniFi custom API request uses `allow-insecure: true` because the controller
  certificate is not valid for the LAN address. The request carries a monitoring
  API key.
- The Beszel adapter is unauthenticated and previously shared the broad
  `domum-proxy` network; it authenticates to Beszel over plain HTTP.
- RSS image URLs were supplied by external feeds without a repository-controlled
  origin policy; current RSS widgets now use text-only `vertical-list`.

These are boundary issues, not reasons to add more dashboard data. The current
public-safe and aggregate widgets must remain stable while the boundaries are
made narrower.

## Current Behavior

- `compose/monitoring/glance.yml` loads `glance.env` as an env source and now
  clears all reserved future variables before Glance starts.
- The UniFi widget sends `${GLANCE_UNIFI_API_KEY}` with `allow-insecure: true`.
- `glance-beszel-adapter` now listens only on the internal
  `glance-beszel-backend` network without endpoint authentication and reaches
  `beszel:8090` over HTTP.
- Current RSS widgets use text-only `vertical-list`; rich feed thumbnails are not
  rendered.
- AdGuard aggregate stats use a username/password web account because a narrower
  account role has not been verified for the installed version.

## Desired Behavior

- Each container receives only the secrets required for its active source. Future
  values in the shared example file must be explicitly cleared or isolated before
  they reach Glance.
- UniFi API credentials are sent only over a connection whose certificate is
  verified, or through a separately approved local trust mechanism. Do not solve
  this by silently switching the API key to cleartext HTTP.
- The Beszel adapter is reachable only by Glance and its Beszel dependency, with
  a narrowly scoped authenticated or network-isolated endpoint and encrypted
  upstream transport where supported.
- Feed images are disabled for current RSS widgets; a compromised feed cannot make
  the browser request arbitrary image hosts through those widgets by default.
- AdGuard access uses a dedicated least-privilege account or an approved
  aggregate-only API mechanism.

## Implementation Plan

1. Done in the repository: Compose explicitly clears every reserved future
   variable before starting Glance, while current Speedtest, AdGuard, and UniFi
   variables remain available. Keep future adapters on separate approved secret
   plumbing. Prefer existing Docker secrets or file-backed `readFileFromEnv`
   support over a new dependency.
2. Verify the live UniFi certificate and endpoint options on the Pi without
   recording private values. Implement a trusted CA path or approved hostname
   route, then remove `allow-insecure: true` and test invalid, expired, and valid
   certificate behavior.
3. Done in the repository: Glance, the adapter, and Beszel share the internal
   `glance-beszel-backend` network, while the adapter no longer joins
   `domum-proxy`. Expose `/summary` only to Glance and use HTTPS upstream if the
   live Beszel endpoint supports it. Add endpoint authentication only if network
   isolation alone cannot prove the caller boundary.
4. Verify AdGuard account roles and replace the operator-account fallback if the
   installed version supports a dedicated aggregate/read-only role. Do not print
   or record credentials.
5. Done: switched all current RSS widgets to text-only `vertical-list`. A future
   image proxy or reviewed origin allowlist requires a separate task.
6. Add failure tests and sanitized documentation for each boundary, including
   unauthorized requests, certificate failures, missing secrets, and changed feed
   image origins.
7. Update the capability matrix and task-63 audit, then mark this task complete
   only after Pi evidence and operator approval are recorded.

## Affected Files

- `compose/monitoring/glance.yml`
- `compose/monitoring/glance-beszel-adapter.yml`
- `compose/monitoring/beszel.yml`
- `compose/monitoring/glance-beszel-adapter/`
- `compose/monitoring/glance/pages/network.yml`
- RSS page files under `compose/monitoring/glance/pages/`
- `config/glance.env.example`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `docs/glance-capability-matrix.md`
- `docs/glance-dashboard-audit.md`
- `backlog/README.md`
- `tests/glance-source-boundary-smoke.sh`

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
summaries. RSS text-only mode changes the visual design but is safer than
allowing arbitrary browser requests. Upstream TLS and secret plumbing still
require coordinated production validation.

## Complexity

Medium-high.

## Suggested Order

Do this after the current task-63 YAML/template corrections and before adding any
new private-personal integration. Remaining order: secret isolation, UniFi TLS,
upstream adapter transport, then AdGuard scope. Adapter network isolation and RSS
image policy are already implemented.

## Decisions and Rejected Alternatives

- Decision: keep current aggregate fields and source limits while hardening the
  transport and credential boundaries.
- Progress: the repository now isolates Glance, the adapter, and Beszel on the
  internal `glance-beszel-backend` network; the adapter no longer joins the broad
  `domum-proxy` network. Pi deployment and caller-boundary evidence remain.
- Progress: Compose now clears reserved future integration variables after
  loading `glance.env`, preventing those values from entering the Glance process.
- Decision: do not expose the host backup heartbeat to Glance; use a reviewed
  summary source or separately approved exporter instead.
- Decision: all current RSS widgets use text-only `vertical-list` because Glance
  v0.8.5 cannot restrict rich-widget image origins. A future image proxy requires
  separate approval; no external thumbnail requests are part of the current RSS
  policy.
- Rejected: retaining `allow-insecure: true` as a permanent exception because the
  request carries a credential.
- Rejected: switching UniFi to cleartext HTTP as a shortcut because it exposes the
  API key on the network.
- Rejected: mounting the host filesystem or Docker socket into Glance to avoid an
  adapter/network decision.
- Decision: private Compose network isolation is the first adapter boundary; it
  does not by itself claim that plaintext upstream traffic is acceptable.
- Rejected: adding a thumbnail proxy or new dependency before proving that a
  no-thumbnail policy is insufficient.
