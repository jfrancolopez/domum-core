# Task 72 - Implement the local Beszel summary adapter for Glance

## Objective

Add the approved tiny internal adapter/exporter that lets Glance read narrow
Beszel host summaries without storing short-lived tokens, widening Beszel trusted
authentication, exposing raw PocketBase data, or mounting Docker/host state into
Glance.

## Background

Task 70 proved the dedicated Glance Beszel username/password can authenticate on
the Pi and see exactly two approved systems, but Glance `v0.8.5` cannot chain the
login token into a second `custom-api` request. A Beszel universal token did not
authorize the systems collection, and a normal PocketBase auth token expires in 7
days. Task 71 selected a local adapter/exporter as the safe bridge.

The existing credential source is `/etc/domum-core/secrets/glance-beszel.env`,
loaded by Glance today and formatted by `config/glance-beszel.env.example`. Keep
that file as the only credential source unless this task proves a concrete reason
to change it and updates the docs.

## Why This Exists

Task 54 cannot add external Hosting metrics until one source family is `Ready` in
the capability matrix. Beszel is still the selected first source family, but the
auth shape must be hidden behind a small maintained component that can refresh
the login token server-side and return only approved summary fields to Glance.

## Current Behavior

- Glance renders no Beszel host metrics.
- `glance-beszel.env` can contain the dedicated username/password plus two system
  labels and IDs, but those IDs are private and untracked.
- The matrix row remains `Needs clarification` because no adapter endpoint exists
  and failure behavior has not been tested.

## Desired Behavior

One internal service exposes a single JSON endpoint for Glance with exactly two
approved host summaries. The output contains display label, reachability/status,
updated/stale timestamp, CPU/load, memory, disk, and temperature only when Beszel
provides clear units and timestamps. Unknown, stale, missing, unauthorized, and
Beszel-down states are explicit and never rendered as healthy.

The adapter must not expose container names, process names, network interface
names, internal addresses, disk serials, raw system IDs, PocketBase user data,
notes, logs, or broad topology.

## Implementation Plan

1. Verify the current service catalog and compose conventions before editing.
   Add the smallest service shape that fits this repository; do not add a new
   stack, database, queue, or monitoring framework.
2. Use standard Debian/container tooling already present in the repo. If a new
   runtime image or language dependency is proposed, stop and record the
   maintenance justification before implementing.
3. Load only the existing `glance-beszel.env` values. Treat missing username,
   password, labels, or IDs as a clear degraded JSON response, not a crash loop.
4. Log in to Beszel server-side, fetch only the configured system records, and
   strip every field except the approved summary fields. Do not print request
   headers, tokens, raw payloads, or system IDs in logs.
5. Cache successful Beszel responses for about 5 minutes and keep a bounded stale
   response for Beszel-down cases. Mark stale distinctly in JSON.
6. Expose one internal endpoint on the Docker network for Glance. Do not publish
   it through Traefik or make it reachable from the LAN.
7. Add a minimal Glance `custom-api` test widget only if this task can validate
   the endpoint safely. Otherwise keep widget rendering for task 54 and only
   prove the adapter endpoint.
8. Update `docs/glance-capability-matrix.md`; move the Host summary row to
   `Ready` only after live success and failure tests prove the source contract.
9. Update `docs/services/glance.md`, `docs/services/beszel.md`,
   `docs/reference/secrets.md`, and any new service docs with deploy, recovery,
   rollback, cache, failure, and maintenance notes.
10. Do not start task 54 in the same commit. Rendering the Hosting widget remains
    the next gated task after this adapter is accepted.

## Runtime Alternatives Research - 2026-08-14

Repository findings:

- There is no existing Dockerfile or repo-local custom service pattern to extend.
- Existing Compose images are purpose-built applications, not generic adapter
  runtimes. Reusing Node-RED, Glance, Beszel, Healthchecks, Homepage, or another
  app image would couple this adapter to an unrelated service lifecycle.
- The service catalog is the single source of truth; a real adapter should either
  be its own disabled-by-default catalog service or be explicitly justified as a
  child of Glance/Beszel in the same compose fragment.

Compared options:

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Pinned `python:3.x-alpine` plus stdlib-only script | No build pipeline, good JSON/HTTP support, straightforward cache/failure tests, no pip packages | New runtime image and maintained script | Recommended if operator approves one new image |
| Repo-built static Go adapter | Small runtime image, typed HTTP/JSON handling, easy single binary | Adds Go toolchain/Dockerfile/build path not used elsewhere in this repo | Selected by operator after research |
| Shell with `curl`/`jq` and BusyBox/httpd | Looks small and familiar | Brittle JSON/auth handling, needs a custom image or package install, harder safe caching and tests | Reject for this auth bridge |
| Reuse an existing app image | Avoids a visibly new image name | Couples adapter health/security to an unrelated service image and may rely on tools not guaranteed by that image | Reject |
| Beszel trusted-auth/header path | Avoids adapter service | Changes Beszel authentication boundary and was not proven safer for this deployment | Deferred by task 71 |

The operator selected the static Go adapter after reviewing these alternatives.
The accepted maintenance cost is a Docker build pipeline using a pinned Go builder
image and a scratch runtime. Do not fall back to shell JSON parsing for this
credential bridge.

## Affected Files

- `bin/domum-core` if the service catalog needs a new service entry
- new compose/service files for the adapter under the existing compose layout
- new adapter source/config files in the smallest repo-local location justified
  by the implementation
- `compose/monitoring/glance.yml` only if Glance needs internal env or network
  wiring for the adapter
- `compose/monitoring/glance/pages/hosting.yml` only for a minimal validated test
  widget, if approved by the implementation
- `config/glance-beszel.env.example` only for non-secret names required by the
  adapter
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/services/beszel.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

Do not modify Beszel data, source hosts, Homepage, Traefik public routing, the raw
Docker socket exposure policy, or live secret values.

## Testing Plan

- Run the repository checks from `AGENTS.md` and the Glance validator.
- Render Compose exactly as CI does for the changed services.
- Run adapter unit or smoke tests for: success, invalid credential, missing env,
  missing system ID, empty system list, Beszel unavailable, slow response,
  malformed response, stale cache, and unauthorized response.
- On the Pi, test from a Glance-equivalent container network location without
  printing credentials, raw IDs, tokens, or raw payloads.
- Cross-check displayed candidate values against the Beszel UI at the same
  timestamp before moving the matrix row to `Ready`.
- Confirm no secrets, system IDs, internal addresses, disk identifiers, container
  names, or private topology appear in Git, logs, rendered HTML, screenshots, or
  JSON returned to Glance.

## Rollback

Revert the adapter commit, update the checkout on the Pi, inspect update
candidates, then run a supervised `sudo domum-core apply` and
`sudo domum-core checkup`. Remove only the adapter service if it was created; do
not delete Beszel data, Glance config, or `/etc/domum-core/secrets/glance-beszel.env`.

## Dependencies

Depends on task 71's operator-selected local adapter path and the existing
dedicated Glance Beszel user. Requires Pi validation before the matrix row can be
marked `Ready` or task 54 can start.

## Risks

The adapter can accidentally widen data exposure if it forwards raw Beszel
records. It also adds a maintained component. Keep the endpoint internal, the
schema small, logs sanitized, caches bounded, and failure states explicit.

## Complexity

Medium. The service should be small, but auth refresh, sanitization, stale data,
and failure tests must be handled carefully.

## Suggested Order

Complete before task 54. If adapter implementation proves too costly or unsafe,
record that decision and ask the operator to choose another external Hosting
source family.

## Decisions and Rejected Alternatives

- Selected: local adapter/exporter. Reason: it can refresh Beszel auth
  server-side, strip fields before Glance sees them, and avoid broad Beszel auth
  changes.
- Runtime selected: repo-built static Go adapter with scratch runtime. Reason: it
  keeps the runtime image minimal and handles HTTP/JSON/caching more safely than
  shell, at the accepted cost of a Docker build pipeline.
- Rejected: static normal PocketBase auth token. Reason: it expires after 7 days.
- Rejected: Beszel universal token as a PocketBase collection bearer token.
  Reason: Pi testing returned zero visible systems.
- Rejected: raw Docker socket or host root mounts in Glance. Reason: prohibited by
  the dashboard program and unnecessarily broad.
- Rejected: shell `curl`/`jq` adapter. Reason: token refresh, sanitization,
  caching, and malformed-response handling are too easy to get wrong in shell.
- Deferred: Beszel trusted-auth/header path. Reason: it changes the auth boundary
  and was not proven safer than the adapter for the running deployment.
