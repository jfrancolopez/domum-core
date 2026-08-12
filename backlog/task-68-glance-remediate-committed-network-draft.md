# Task 68 - Remediate committed unsafe Glance Network draft

## Objective

Review and remove or replace the previously committed Glance Network draft so it
cannot be accidentally included by a future modular configuration. Do not add a
Network dashboard in this task.

## Background

The recovered production Glance configuration is an inline two-page dashboard
and does not load `pages/network.yml` or `widgets/network/`. Repository
validation found the committed Network draft fails `yamllint` and uses invented
widget types and undocumented relative APIs. The task-47 audit also proved that
`dash` is public, while the draft proposes household WAN, DNS, UniFi, and
Tailscale data.

The operator authorized removal of uncommitted Glance implementation in task 67
only. This committed draft must be reviewed separately rather than silently
reverted or deployed.

## Why This Exists

A future task-51 include migration could make invalid Network YAML active,
reintroducing a Glance configuration outage. The fake source assumptions also
conflict with the approved capability matrix and privacy boundary.

## Current Behavior

- `compose/monitoring/glance/pages/network.yml` and its referenced
  `widgets/network/` files are committed but inactive.
- They fail repository YAML lint due to trailing whitespace and missing final
  newlines.
- They define unsupported `network/*` widget types and make unverified API,
  credential, cache, and privacy claims.
- The approved capability matrix marks all deep Network data as blocked,
  unverified, or not recommended until later tasks.

## Desired Behavior

- No inactive tracked Network draft can be mistaken for production-ready Glance
  configuration.
- The only future Network implementation begins in tasks 55 and 56 from the
  approved matrix after task 49 proves private access.
- Repository YAML lint passes without suppressing rules.

## Implementation Plan

1. Read `AGENTS.md`, the Glance program charter, task-47 audit, task-48
   architecture/matrix, and the complete diff of the original Network commit.
2. Present the operator with two explicit choices before editing:
   - revert/remove the inactive Network page and widget draft; or
   - retain only documented, public-safe native configuration that is proven
     compatible with Glance `v0.8.5`.
3. Do not retain custom templates unless every request, response field,
   credential, provenance, timeout, cache, privacy class, and fallback is
   approved in the matrix.
4. Remove unsupported `network/*` widget types, fabricated status assumptions,
   and any static identifiers. Do not replace them with placeholders.
5. Keep the restored running Glance config and `dash` router intact.
6. Do not alter Speedtest Tracker, AdGuard, UniFi, Tailscale, gateway, Traefik,
   DNS, firewall, source services, or credentials.
7. Validate the full repository YAML tree, Glance configuration, running
   container, and `dash` availability. Update documentation/status only after
   operator acceptance.

## Affected Files

- `compose/monitoring/glance/pages/network.yml`
- affected inactive files under `compose/monitoring/glance/widgets/network/`
- `docs/glance-capability-matrix.md` only to correct stale provenance/status
- `docs/services/glance.md` only if it makes an obsolete Network claim
- `backlog/README.md` (status only after completion)

Do not edit Homepage, the restored `glance.yaml`, the `dash` router, runtime
data, secret files, or unrelated Glance tasks.

## Testing Plan

- Run `git diff --check`, `yamllint -c .yamllint.yml .`, and the standard shell
  checks.
- Run version-matched Glance validation once task 50 supplies it; before then,
  state that full semantic validation is unavailable.
- Confirm Glance remains running, logs contain no config error, and `dash`
  returns HTTP 200 locally.
- Run gitleaks if installed; otherwise record the unavailable tool.

## Rollback

Revert only the remediation commit and recreate only Glance if the removed draft
is needed for historical comparison. Never restore it into the active config,
delete secrets, or use `docker compose down`.

## Dependencies

Requires approved task 48. Must complete before task 51 can safely introduce a
complete include tree. Network implementation still requires tasks 49, 55, and
56 in order.

## Risks

Removing a committed draft changes history forward, but retaining it risks an
outage or private-data leak. Keep the change narrow, preserve Git history, and
obtain explicit operator choice rather than assuming a rollback preference.

## Complexity

Small remediation; low runtime risk because the draft is inactive.

## Suggested Order

Run after task 48 approval and before task 50/51 runtime and modularization
work.
