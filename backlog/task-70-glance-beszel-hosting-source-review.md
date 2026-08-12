# Task 70 — Review Beszel as the Glance external Hosting source

## Objective

Turn Beszel-managed external hosts into an eligible task-54 source family, or
record why Glance should not consume Beszel directly. This task does not render a
Glance widget by itself.

## Background

The operator selected Beszel-managed external hosts as the first task-54 family.
Task 54 requires one fully `Ready` external Hosting source before implementation.
The current capability matrix still marks Beszel host summary as `Needs
clarification`, and the repository only documents existing Homepage Beszel
username/password variables plus unverified external-host system IDs. Glance has
no Beszel credential plumbing today.

Homepage documentation records that Unraid and `domum-core-media` Beszel cards
previously produced widget API errors when using the tracked placeholder system
IDs. Those failures must be resolved before Glance repeats the same integration.

## Current Behavior

- Beszel hub and local `beszel-agent` are tracked in
  `compose/monitoring/beszel.yml`.
- The local Beszel agent monitors `domum-core` through a Unix socket and has
  Docker/SMART access inside the agent container.
- Homepage may use `HOMEPAGE_VAR_BESZEL_USERNAME`,
  `HOMEPAGE_VAR_BESZEL_PASSWORD`, and per-system ID variables from
  `config/homepage.env`, but those are Homepage-specific and not approved for
  Glance reuse.
- Glance has no Beszel username/password, token, or system ID environment
  variables.
- The public Beszel README says API access exists, but this session did not find
  a stable versioned API contract suitable for a Glance `custom-api` widget.

## Public Source Review Findings — 2026-08-12

This review used only tracked repository facts and public upstream Beszel source;
it did not inspect live Beszel data, credentials, system IDs, or `data/`
directories.

- Beszel is built on PocketBase and the web UI uses the PocketBase JavaScript
  client.
- Upstream source defines authenticated PocketBase-style collections including
  `systems`, `system_stats`, `containers`, `container_stats`, `system_details`,
  `systemd_services`, `smart_devices`, and `user_settings`.
- Upstream collection rules allow authenticated users to read systems they are
  members of. If `SHARE_ALL_SYSTEMS=true`, authenticated users can read all
  systems. Write rules exclude users whose role is `readonly`.
- Upstream custom `/api/beszel/*` routes require authentication for `/info`,
  `/getkey`, `/universal-token`, `/systemd/info`, `/containers/logs`,
  `/containers/info`, and `/smart/refresh`; admin or non-readonly role is
  required for some routes.
- Beszel has a readonly role, but the repo does not yet contain an approved
  Glance-specific system-ID inventory.
- The operator created a dedicated Glance Beszel username/password. The values
  belong only in `/etc/domum-core/secrets/glance-beszel.env`, using
  `config/glance-beszel.env.example` as the format.
- The README says API access exists, but a stable OpenAPI/versioned API contract
  was not found. A Glance integration would therefore depend on PocketBase
  collection behavior plus live-version testing, not a separately versioned
  Beszel API document.

Decision: keep the matrix row at `Needs clarification`. Do not implement task 54
until Pi-only credential and system coverage checks prove a narrow readonly path.

## Pi API Test Findings — 2026-08-12

The operator populated `/etc/domum-core/secrets/glance-beszel.env` with the
dedicated Beszel credentials and two system IDs. A sanitized root-only test on the
Pi proved:

- the env file loads and contains non-empty username, password, and two system
  IDs;
- password auth against Beszel succeeds from the host using the `domum-proxy`
  container address;
- the dedicated Beszel user can see exactly two systems;
- both configured system IDs match visible systems;
- a permanent Beszel universal token can be generated, but it returns zero
  visible `systems` records when used as `Authorization: Bearer <token>` against
  the PocketBase collection API.

Glance `v0.8.5` `custom-api` subrequests are concurrent and cannot use the token
returned by a login request as the header for a second request in the same widget.
Because the universal token does not authorize the collection query, the current
native Glance options cannot safely render Beszel host metrics from the approved
username/password alone. Implementing this would require either an approved
long-lived PocketBase auth token, a narrow local adapter/exporter, or upstream
Beszel support for a read token that can query selected system records.

## Desired Behavior

Before task 54 implements anything, the repo should know exactly how Glance may
read Beszel: official API endpoint/version, authentication mechanism, least
privilege scope, host IDs or aliases, allowed fields, cache, timeout, stale
behavior, and failure states. External host names, addresses, VM/container names,
or topology must not be exposed unless explicitly approved.

## Implementation Plan

1. On the Pi, inventory Beszel version, configured systems, approved display
   aliases, and whether `domum-core-media` or other external hosts are actually
   present. Do not print addresses, internal IDs, tokens, or private notes.
2. Verify Beszel's supported API for the running version from official docs,
   upstream source, or authenticated hub behavior. Record request paths, methods,
   response fields, authentication headers/cookies, pagination, and error shapes.
3. Decide whether Glance should use a dedicated Beszel read-only credential,
   a token, or no integration. Do not reuse a Homepage admin password unless the
   operator explicitly approves that risk and no narrower mechanism exists.
4. Define secret names and recovery handling only after the credential model is
   selected. Candidate names must live under `/etc/domum-core/secrets` and be
   documented without values.
5. Choose the first external host set and allowed fields. Start with status,
   updated timestamp, CPU, memory, disk, temperature, and load only if the API
   exposes those values with clear units and timestamps.
6. Test successful, unauthorized, missing-system, empty, stale, slow, malformed,
   and version-changed responses from inside a container-equivalent network
   path, without logging credentials or payloads.
7. Update `docs/glance-capability-matrix.md`. Move the Beszel row to `Ready`
   only when the exact source, credential, fields, privacy, and failure behavior
   are documented.
8. Then return to task 54 and implement exactly that reviewed Beszel family.

Review progress: items 1, 2, 3, 4, and 5 are partially complete. Item 6 found a
blocking auth-token shape for native Glance. Item 7 remains blocked; do not move
the matrix row to `Ready` until one approved read-token or adapter path exists.

## Affected Files

- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/services/beszel.md`
- `docs/reference/secrets.md` after a credential model is approved
- `backlog/README.md`
- A future task-54 implementation may add templates under
  `compose/monitoring/glance/widgets/servers/`

Do not modify Beszel data, agents, source hosts, Docker socket access, Homepage,
or Glance page YAML in this review task unless it is only documentation of the
approved source contract.

## Testing Plan

- Run repository syntax/lint checks for any docs/config changes.
- On the Pi, test the selected API from a Glance-equivalent network path.
- Cross-check displayed candidate values against the Beszel UI at the same
  timestamp before marking the row `Ready`.
- Verify that no credentials, private host IDs, addresses, or topology enter Git,
  logs, screenshots, or rendered HTML.

## Rollback

Revert this documentation task. It does not change services or credentials.

## Dependencies

Requires operator-selected Beszel priority from task 54 and access to the live
Beszel hub for sanitized API review.

## Risks

Beszel can expose sensitive host topology, container names, network interfaces,
disk identifiers, and historical behavior. A broad admin credential would also
be high-impact if leaked. Prefer a narrow read-only mechanism and render only
approved summaries.

## Complexity

Small-medium review task; medium privacy risk if source fields are mishandled.

## Suggested Order

Complete before task 54 implementation. If Beszel cannot provide a safe stable
read API, ask the operator to choose the next external Hosting family instead.
