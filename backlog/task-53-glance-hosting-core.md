# Task 53 - Build the core Glance Hosting page

## Objective

Build the first Hosting page for domum-core and systems already represented by the same approved Beszel/health sources. Summarize specialist systems without recreating Beszel. Proxmox, Unraid, Kubernetes, and cloud APIs belong to task 54.

## Background

The eventual estate includes the production RPi5, an N100 media server, Unraid,
Proxmox, Talos/Kubernetes, cloud servers, and other Linux hosts. Their actual
availability and approved aliases come from task 47. API-first is the operator's
chosen policy. Glance currently has no host metric widget and deliberately has
no Docker socket or host filesystem mount. Existing docs state that
container-local values must not be presented as Pi metrics.

Read the program charter, approved audit, architecture, and every Hosting matrix
row before editing. Implement only `Ready` rows.

## Current Behavior

Glance shows a compact HTTP monitor and GitHub releases but no trusted host,
backup, certificate, container-health, or infrastructure history summaries.
Beszel is the existing source for Pi/container history.

## Desired Behavior

Hosting quickly identifies unhealthy or capacity-constrained systems, recent
backup state, relevant releases, and where deeper investigation belongs. Values
identify their source and age. Trends are shown only when an existing API
provides history. Unknown is visually distinct from healthy.

## Implementation Plan

1. Start with domum-core and existing read-only sources such as Beszel,
   Healthchecks, update/release metadata, and documented backup status APIs or
   files already exposed safely. Never mount restic repositories, host root, or
   Docker socket into Glance.
2. For each metric, document source, unit, timestamp, stale threshold, supported
   cache/timeout behavior, and failure state. Do not combine incompatible samples.
3. Show a concise host card/table: uptime, CPU/load, RAM, disk, temperature, and
   container/agent status only where the source API provides them accurately.
4. Apply approved thresholds to structured values: temperature below 65 C
   normal, 65-74 warning, 75+ critical; disk below 75% normal, 75-89 warning,
   90+ critical; RAM below 80% normal, 80-89 warning, 90+ critical. If host
   baselines require different thresholds, record the approved exception.
5. Add backup/healthcheck summaries without exposing repository URLs, check
   UUIDs, snapshot IDs, or secret ping URLs. Link to specialist UIs for detail.
6. Add selected installed-project releases with long caches; do not claim an
   available release is an approved update.
7. Add external hosts only when the same approved Beszel source already exposes
   them without new agents or credentials. Defer Proxmox, Unraid, Kubernetes,
   cloud, socket proxy, SSH, adapter, and new-agent work to task 54.
8. Use lightweight bars/sparklines only from real historical arrays. If an API
   exposes current values only, show current values rather than synthetic history.
9. Update the matrix with tested status, provenance for community templates,
   measured request/resource cost, and any omitted hosts.
10. Obtain operator approval of core Hosting before task 54.

## Affected Files

- `compose/monitoring/glance/pages/hosting.yml`
- approved Hosting templates under `compose/monitoring/glance/widgets/servers/`
- approved shared CSS only if task 51 established that location
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` for credential names/scopes only
- `backlog/README.md` (status only)

Do not modify Beszel, Docker networks/socket access, source hosts, Homepage, or
infrastructure APIs.

## Testing Plan

- Run all repository, Compose, Glance, yamllint, and gitleaks validation.
- Test each API with real read-only data and simulated unavailable/stale/partial
  responses without logging credentials or payloads.
- Cross-check displayed values against the source UI at the same timestamp.
- Verify threshold boundaries and unknown/stale coloring.
- Test all target widths; tables must collapse without horizontal overflow.
- Measure page request count/bytes and Glance CPU/RAM versus Home.
- Record host/API checks that require separate environments as untested.

## Rollback

Revert the core Hosting commit, update the checkout, then run a supervised
full-stack apply and checkup after inspecting update candidates. No source host,
agent, or data is changed.

## Dependencies

Requires approved task 52 and `Ready` core Hosting matrix rows. Any adapter, new
agent, SSH mechanism, or source-service change requires a new task and operator
approval.

## Risks

False health is more dangerous than missing data. Stale cache, unit conversion,
or container-local metrics can mislead. Label age/source and prefer unknown over
green when data is absent.

## Complexity

Medium due to one primary source family; low-medium operational risk.

## Suggested Order

Phase 3. Land domum-core coverage before external Hosting.