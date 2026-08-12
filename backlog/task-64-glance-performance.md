# Task 64 — Validate Glance failures and performance

## Objective

Exercise every approved page against empty, stale, malformed, unauthorized,
rate-limited, slow, and unavailable sources; then tune supported cache/list/image
limits to keep the RPi5 and clients within the approved budget. Add no sources.

## Background

Tasks 52-61 test integrations individually, task 62 unifies presentation, and
task 63 audits source/privacy safety. Total behavior can still differ when all
pages and caches coexist. Upstream Glance normally fetches on page load and
serves cached responses rather than continuously polling in the browser.

## Current Behavior

Use task 47's baseline and each page's measured deltas. Every widget should have
a matrix row with fixed or configurable cache behavior, request/image limits,
fallback semantics, and live-test status.

## Desired Behavior

One failed API never dominates a page. Unknown/stale is never healthy. Cold and
warm loads are measured honestly. Direct and embedded pages work at all target
widths, and total Glance CPU/RAM/network/image cost stays within task 48's budget.

## Implementation Plan

1. Freeze integration scope and create a page-by-page failure/performance test
   table from the capability matrix.
2. Exercise each practical failure class without changing source services or
   logging private payloads. Use safe test fixtures/mocked endpoints where a real
   outage would be disruptive; label fixture versus live tests.
3. Verify timestamps, stale thresholds, unknown/offline colors, compact error
   height, links, image fallback, and recovery after source restoration.
4. Measure repeatable cold/warm load time, requests, transferred bytes/images,
   and Glance CPU/RAM for each page and an ordinary multi-page session.
5. Tune only controls supported by the pinned version. Prefer fewer items/images
   and longer cache over code or new infrastructure.
6. Recheck direct and Homepage-embedded use at 1920, 1440, 1024, 768, 430, and
   390 px after tuning.
7. Update matrix/results and list anything untested or over budget. Remove a
   low-value widget rather than waiving a meaningful budget without approval.

## Affected Files

- existing files under `compose/monitoring/glance/` for bounded tuning/removal
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `backlog/README.md` (status only)

Do not add integrations, adapters, dependencies, source changes, or Homepage edits.

## Testing Plan

- Run repository, Compose, full Glance, YAML, and secret validation.
- Complete the page-by-page failure/performance table on the Pi.
- Compare final numbers with task 47 and page baselines using the same method.
- Verify all target widths, links, images, overflow, and source recovery.
- Obtain operator acceptance of remaining limits before recovery documentation.

## Rollback

Revert tuning/removal changes, update the checkout, then run a supervised
full-stack apply and checkup after inspecting update candidates. No source data
or credential is changed.

## Dependencies

Requires completed and accepted task 63.

## Risks

Failure testing can disrupt real services if done carelessly, and warm caches can
hide cost. Prefer fixtures, identify live tests, preserve source systems, and
report cold and warm results separately.

## Complexity

Medium focused Pi validation; low-medium operational risk.

## Suggested Order

Phase 6 after security/privacy review and before recovery proof.
