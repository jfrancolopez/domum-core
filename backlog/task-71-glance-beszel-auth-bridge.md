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

## Token Evaluation — 2026-08-12

A sanitized Pi test checked the normal PocketBase auth token returned by
`/api/collections/users/auth-with-password` for the dedicated Glance Beszel user.
That token can query the `systems` collection and sees the two approved systems,
but it expires after 604800 seconds, or 7 days. Treating it as a static Glance
secret would silently break the dashboard weekly unless refreshed out of band.

Rejected as the default implementation: store a normal PocketBase auth token in
`glance-beszel.env`. Reason: the token is short-lived and Glance cannot refresh
it before issuing the second request.

Still rejected from task 70: Beszel permanent universal token as a bearer token
for PocketBase collections. Reason: the token can be generated, but it returned
zero visible `systems` records when used against the collection API.

The operator selected the local adapter/exporter path on 2026-08-14:

- Small local adapter/exporter: logs in to Beszel with the dedicated credential,
  fetches exactly the two configured systems, strips disallowed fields, and
  exposes one internal JSON endpoint for Glance. This adds a maintained
  component, but it avoids weekly token expiry, avoids widening Beszel trusted
  authentication, preserves least privilege, and keeps Glance's widget simple.

Rejected for this phase:

- Beszel trusted-auth/header or upstream-supported token path: deferred because
  it changes who can assert an identity to Beszel and no long-lived narrow read
  token was proven for the running version.

## Desired Behavior

Glance can read exactly the approved Beszel summaries without committing secrets,
using a mechanism with clear lifetime, recovery, failure behavior, and limited
scope. The rendered data must be status/timestamp/capacity summary only, not
container names, network interface names, IPs, disk serials, or broad topology.

## Implementation Plan

1. Record the operator-selected adapter/exporter path without adding the adapter
   in this task.
2. Keep the existing `/etc/domum-core/secrets/glance-beszel.env` as the only
   credential source; do not create token files or reuse Homepage credentials.
3. Reject options that require raw Docker socket access in Glance, host root
   mounts, Homepage credential reuse, superuser credentials, committed tokens,
   weekly static token refresh, or broad Beszel trusted-auth changes.
4. Document recovery impact: the adapter will be Git-recreated; only the existing
   env file remains secret/recovery-pack state.
5. Update `docs/glance-capability-matrix.md`. Keep Beszel host summary at `Needs
   clarification` until the adapter is implemented and proven with
   unavailable/unauthorized/empty, malformed, slow, stale, and missing-system
   tests.
6. Add the next implementation task for the adapter. Return to task 54 only after
   that task moves the Beszel row to `Ready`.

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
