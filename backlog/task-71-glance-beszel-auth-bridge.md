# Task 71 — Choose a safe Beszel-to-Glance auth bridge

## Objective

Select and prove one safe way for Glance to read the two approved Beszel systems,
then unblock task 54. This task chooses the auth/data path; it does not add broad
host metrics until the path is proven.

## Background

The operator created a dedicated Glance Beszel user and populated
`/etc/domum-core/secrets/glance-beszel.env` with credentials plus two Beszel
system IDs. A sanitized Pi test proved password auth works and both configured
IDs match the two systems visible to that user.

Glance `v0.8.5` cannot directly use that username/password in one native
`custom-api` widget because subrequests are concurrent and cannot use the token
returned by a login request as a header for a second request. A Beszel permanent
universal token was generated successfully, but using it as a bearer token against
the PocketBase `systems` collection returned zero visible systems.

## Current Behavior

- `compose/monitoring/glance.yml` optionally loads
  `/etc/domum-core/secrets/glance-beszel.env`.
- The env file is the only supported Glance Beszel credential source.
- Beszel system IDs are verified locally but private and not committed.
- No Glance widget renders Beszel host metrics yet.

## Desired Behavior

Glance can read exactly the approved Beszel summaries without committing secrets,
using a mechanism with clear lifetime, recovery, failure behavior, and limited
scope. The rendered data must be status/timestamp/capacity summary only, not
container names, network interface names, IPs, disk serials, or broad topology.

## Implementation Plan

1. Re-test Beszel collection access with the documented dedicated user and record
   exact request shape, response fields, and errors without printing secrets or
   system IDs.
2. Evaluate option A: a long-lived PocketBase auth token or supported Beszel API
   token that can read only the selected records. Reject it if token lifetime,
   revocation, role scope, or recovery is unclear.
3. Evaluate option B: a tiny local read-only adapter/exporter that logs in to
   Beszel server-side, fetches the two configured systems, strips disallowed
   fields, and exposes one internal JSON endpoint for Glance. This requires a
   separate operator decision because it adds a maintained service/process.
4. Reject options that require raw Docker socket access in Glance, host root
   mounts, Homepage credential reuse, superuser credentials, or committed tokens.
5. Document the selected credential names, modes, recovery-pack impact, request
   count/cache, timeout, stale threshold, and failure behavior.
6. Update `docs/glance-capability-matrix.md`. Move Beszel host summary to
   `Ready` only after one path is proven with unavailable/unauthorized/empty and
   stale/failure tests.
7. Return to task 54 to render the actual Hosting widget.

## Affected Files

- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/services/beszel.md`
- `docs/reference/secrets.md`
- `backlog/README.md`
- If option B is selected later: new compose/service files and docs from a
  separate approved implementation task.

Do not modify Beszel data, rotate credentials, expose private IDs, or add an
adapter without explicit operator approval.

## Testing Plan

- Run repository syntax/lint, Glance config validation, Compose rendering, and
  `tests/gitleaks-tracked.sh` for docs/config changes.
- On the Pi, prove the selected request path from a Glance-equivalent network
  location.
- Test invalid credential, revoked/expired token, missing system ID, empty system
  list, Beszel unavailable, slow response, and malformed response.
- Confirm no secrets, IDs, tokens, or private topology appear in Git, logs,
  screenshots, or rendered HTML beyond approved display labels.

## Rollback

Revert the bridge-selection commit. If a later adapter is added, revert that
separate implementation and remove only its service, not Beszel data or secrets.

## Dependencies

Depends on task 70 Pi API findings and the operator-created dedicated Beszel user.

## Risks

Token misuse could expose more Beszel data than intended. An adapter adds another
component to maintain. Prefer no widget over a broad or brittle credential path.

## Complexity

Small-medium if a safe token exists; medium if an adapter is required.

## Suggested Order

Complete before task 54. If no safe path is acceptable, choose a different task-54
external Hosting family.
