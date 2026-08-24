# Task 63 — Audit Glance sources and privacy

## Objective

Audit every rendered widget, external request, copied template, credential scope,
and exposed field across the seven pages. Remove unsafe or unjustified content.
Do not perform the failure/performance campaign assigned to task 64.

## Background

Tasks 52-61 add pages and approved source families; task 62 unifies presentation.
Community custom API templates may be vetted upstream but remain local code that
can expose headers, unsafe HTML, mutable endpoints, private images, or excessive
data. The dashboard contains private calendar/network/media/gaming information
and is intended for LAN/Tailscale only.

## Current Behavior

Each widget should have capability-matrix provenance and privacy rows, but
page-by-page review may leave inconsistent escaping, stale source references,
overbroad credentials, duplicate fields, or private values in URLs/logs/images.

## Desired Behavior

Every rendered field and request is justified, minimally private, read-only, and
traceable to a reviewed source/version. Secrets are absent from Git, rendered
HTML, browser URLs, logs, and screenshots. External non-tailnet access remains
denied. Unsafe widgets are removed rather than patched with speculative defenses.

## Implementation Plan

1. Inventory every rendered widget and remove duplicates, placeholders, weak
   cards, and anything that only mirrors Homepage or a specialist UI.
2. Audit native/custom/iframe classification, all URLs/subrequests/headers/image
   origins, immutable provenance, license, maintenance, API version/rate limit,
   HTML escaping/injection, JavaScript, shell/extension behavior, and cache model.
3. Reject mutable remote YAML/scripts, unapproved extensions/adapters, command
   execution, unsafe HTML, and unsupported visual claims.
4. Review each credential for minimum read-only scope, external file ownership,
   variable naming, log behavior, recovery inventory, and source isolation.
5. Review each public/internal IP, hostname, family event, media title/user,
   Steam/friend field, Tailscale/UniFi/DNS identifier, and image against its
   approved privacy level. Remove unapproved fields.
6. Inspect Git, rendered HTML, browser network URLs, Glance/Traefik logs, and
   sanitized screenshots without recording private payloads. Re-test external
   non-tailnet denial.
7. Verify thresholds, units, timestamps, sorting, bars, and trends are based on
   real structured source values; remove synthetic or misleading output.
8. Update capability/provenance/credential documentation and hand a clean frozen
   widget inventory to task 64. New defects or source changes become new tasks.

## Affected Files

- existing files under `compose/monitoring/glance/` only to remove or correct an
  already approved widget; no new integration families
- `docs/glance-capability-matrix.md`
- `docs/glance-dashboard-architecture.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md` and new defect tasks when required

Do not modify Homepage, source services, global network/authentication policy, or
add dependencies/adapters.

## Testing Plan

- Run all repository, Compose, full Glance, YAML, and gitleaks checks.
- Complete a source/privacy checklist for every matrix row.
- Verify secret/private values are absent from Git, HTML, URLs, logs, and tracked
  screenshots; record method without values.
- Re-test LAN, Tailscale, and external non-tailnet access.
- Have the operator approve the final field-level privacy inventory.

## Rollback

Revert the security-review commit, update the checkout, then run a supervised
full-stack apply and checkup after inspecting update candidates. If rollback
restores an unsafe widget, disable that page/widget until a corrected task lands.

## Dependencies

Requires operator-approved tasks 50 through 62. Integration scope is frozen.

## Risks

Audit output itself can leak topology or personal content. Record categories,
names, scopes, and results, never values/payloads. Favor removal over clever
sanitization when behavior is uncertain.

## Complexity

Medium focused source/privacy review; low-medium privacy risk.

## Suggested Order

Phase 6 after visual polish and before task 64 performance/failure validation.

## Progress Record

- Static review completed against the current v0.8.5 page tree and capability
  matrix without reading live secrets or data directories.
- Commit `3c0a8e7` added explicit unavailable states for custom API widgets,
  corrected Speedtest response paths and JSON headers, bounded Steam and UniFi
  output, added bounded Beszel capacity fields, removed a stale WSJ feed, removed
  unused Glance AdGuard environment plumbing, and corrected source/documentation
  assignments.
- The review found no tracked secret values, unapproved rendered identities,
  unsupported widget types, arbitrary JavaScript, remote YAML, shell execution,
  or raw Docker socket use.
- Residual source-boundary findings are recorded in task 79: UniFi TLS
  verification, Beszel adapter upstream transport, and AdGuard least-privilege
  verification. Reserved future variables are now cleared before Glance starts,
  and current RSS widgets use text-only style as the safe image-origin policy.
- Task 64 remains blocked until the privacy review and operator approval are
  complete. Pi-only browser, failure, rendered-HTML, and performance evidence is
  still required.
