# Task 48 — Define Glance architecture, privacy, and capability matrix

## Objective

Convert the approved live audit into a concrete page map, data-source map,
privacy model, access prerequisite, widget capability matrix, and phase budget.
This is a documentation/design task; do not implement widgets or change live
access controls.

## Background

The operator selected seven phased pages: Home, Hosting, Network, Media, Games,
News, and Social. Homepage remains the launcher and fast operations portal.
Glance is the deeper private daily dashboard. Exact service availability and
operator details come only from task 47's approved audit. The dashboard will
eventually span an RPi5, N100 media host, Unraid, Proxmox, Kubernetes/Talos,
cloud systems, and more, but absent systems must not produce placeholders.

Read `AGENTS.md`, `backlog/glance-dashboard-program.md`, and the entire task 47
audit before editing. Verify task 47 is accepted in `backlog/README.md`.

## Current Behavior

The repository has no capability matrix, cache budget by widget, data-source
map, credential inventory for Glance, or documented privacy classification.
Existing architecture docs constrain Glance to a limited overview and need a
deliberate role update before implementation.

## Desired Behavior

Another lower-cost model can open one page task and know exactly which widgets
are authorized, their source and credential mechanism, whether they are native
or custom, cache target, privacy/resource risk, fallback, and readiness. The
design distinguishes verified support from aspiration and resolves the access
boundary before private data.

## Implementation Plan

1. Update `docs/dashboard-architecture.md` to preserve Homepage ownership while
   defining Glance's deeper role. Do not modify Homepage itself.
2. Create `docs/glance-dashboard-architecture.md` with page purposes, page
   order, information hierarchy, cross-page duplication rules, responsive
   strategy, failure behavior, and source-of-truth layout under
   `compose/monitoring/glance/`.
3. Create `docs/glance-capability-matrix.md`. Include every requested widget,
   including unsupported and deferred requests. Required columns are defined
   in the program charter. Add exact source/API documentation links and the
   Glance version against which support was checked.
4. Classify each visualization as native, reviewed community template, local
   custom API template, iframe, or not safely supported. Explicitly record that
   Glance is not Grafana and does not generally background-poll widgets.
5. Define privacy levels: public-safe, private-operational, private-personal,
   and secret. Map every widget and field to a level. Private-personal content
   is blocked until LAN/Tailscale-only reachability is proven.
6. Document the desired access outcome and a separate implementation decision
   gate. Compare only mechanisms compatible with the existing Traefik/Cloudflare
   design. Do not silently choose or deploy authentication, firewall, DNS, or
   proxy changes. Record rejected options and reasons.
7. Create a credential inventory with variable/file names only, read-only scope,
   owning widget, rotation owner, and whether the credential is recoverable via
   the encrypted recovery pack. Do not create credentials.
8. Set per-widget cache, timeout, list, image, and request-count budgets where
   that widget/version exposes controls. Record fixed upstream behavior and
   widgets with no network request rather than inventing unsupported properties.
9. Define measurable phase acceptance: page load, API failure state, Glance
   CPU/RAM delta, request count, image bytes, all target widths, and secret scan.
10. Resolve whether a source needs an adapter. Mark it `Not recommended` unless
    no documented read-only alternative exists; adapters need a future separate
    task and approval, not implementation here.

## Affected Files

- `docs/dashboard-architecture.md`
- `docs/glance-dashboard-architecture.md` (new)
- `docs/glance-capability-matrix.md` (new)
- `docs/README.md`
- `backlog/README.md` (status only)

## Testing Plan

- Trace every operator request in task 47 and the program charter to a matrix
  row or an explicitly rejected/deferred decision.
- Confirm every `Ready` row has a verified source and version-compatible widget
  mechanism; downgrade anything uncertain.
- Confirm every credential row contains names/scopes but no values.
- Check links, `git diff --check`, yamllint for any YAML examples, and gitleaks.
- Obtain operator approval for the architecture, privacy model, access gate,
  first Home scope, and cache budget.

## Rollback

Revert the architecture commit. No production state is changed.

## Dependencies

Requires completed and operator-approved task 47. Blocks all implementation.

## Risks

Overdesign and unsupported promises are the primary risks. Prefer a smaller
`Ready` set and explicit deferred rows. Do not confuse cache age with live
browser refresh or infer API support from screenshots.

## Complexity

Medium documentation and architecture work; no operational risk.

## Suggested Order

Phase 0, immediately after task 47.
