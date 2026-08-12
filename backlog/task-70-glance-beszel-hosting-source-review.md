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
