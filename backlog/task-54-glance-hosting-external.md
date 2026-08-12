# Task 54 — Add one external Hosting source family

## Objective

Extend Hosting with exactly one highest-priority external platform family marked
`Ready` in the capability matrix: existing Beszel-managed hosts, Proxmox, Unraid,
Kubernetes/Talos, or cloud systems. Do not integrate multiple new API families in
one session.

## Background

Task 52 establishes domum-core and same-source core hosting behavior. The future
estate may include an N100 media host, Unraid, Proxmox, Kubernetes/Talos, and
cloud servers, but task 47 determines what exists. The operator chose API-first.
Glance must summarize and link to specialist tools, not reproduce their UIs.

## Current Behavior

Use the accepted task-53 page and task-48 matrix as facts. Rows without verified
API versions, read-only credentials, privacy decisions, and source ownership are
not eligible. No new agent, socket proxy, SSH key, or adapter is authorized.

## Desired Behavior

One external family adds concise health/capacity/context with source age and
failure semantics consistent with core Hosting. Remaining families stay
explicitly deferred and receive separate tasks after their prerequisites exist.

## Implementation Plan

1. Select one `Ready` family with the operator; record why it has highest value.
2. Verify official API schema/version and minimum read-only credential scope.
3. Prefer native support, then audit one community template or build one local
   custom API template. Record immutable provenance and all requests/headers.
4. Show only approved summary fields and real historical arrays. Do not expose
   VM/container names, addresses, cluster topology, or tenant data unless the
   matrix explicitly permits them.
5. Label timestamp/staleness and use the existing Hosting thresholds only where
   units and semantics match.
6. Set supported cache/timeouts and cap requests/items. Test unavailable,
   unauthorized, partial, empty, stale, and version-changed responses.
7. Update docs/matrix and create new numbered backlog tasks for other now-Ready
   families; do not absorb them here.
8. Obtain operator approval before core Network.

## Affected Files

- `compose/monitoring/glance/pages/hosting.yml`
- one family directory under `compose/monitoring/glance/widgets/servers/`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` for names/scopes only
- `backlog/README.md` and new follow-up task files if justified

Do not modify source platforms, agents, Homepage, networks, or authentication.

## Testing Plan

- Run repository, Compose, Glance, YAML, and secret validation.
- Cross-check values against the source UI/API at the same timestamp.
- Exercise all failure/stale cases and target viewport widths.
- Measure incremental requests, bytes, CPU, and RAM against task 53.
- Verify only one new API family appears in the diff.

## Rollback

Revert this family commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting pending update candidates. Never delete or
rotate the source credential during rollback.

## Dependencies

Requires approved task 53 and one fully `Ready` external Hosting family.

## Risks

External APIs can expose sensitive topology and drift across versions. One-family
scope, read-only credentials, stale labeling, and compact failures limit risk.

## Complexity

Medium for one source family; medium privacy/integration risk.

## Suggested Order

Phase 3 after core Hosting. Additional families require separate future tasks.
