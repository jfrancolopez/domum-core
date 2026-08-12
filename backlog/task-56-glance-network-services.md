# Task 56 — Add one deep Network source family

## Objective

Add exactly one highest-priority deep network source marked `Ready`: DNS,
UniFi/gateway, or Tailscale. Keep the core WAN/Speedtest page from task 55 stable
and create separate follow-up tasks for other source families.

## Background

DNS may expose query/client behavior, UniFi exposes topology and clients, and
Tailscale exposes devices, owners, addresses, and update state. These are not one
privacy/API problem. The operator wants deep private networking, but access must
remain LAN/Tailscale-only and every field needs explicit classification.

## Current Behavior

Task 54 provides WAN quality, Speedtest history, and bounded latency/outage
context. Exact DNS, gateway/UniFi, and Tailscale systems/API readiness come from
tasks 47-48. No family is implied present or authorized.

## Desired Behavior

One additional source provides useful bounded summaries with no raw logs or
unapproved identifiers. It has read-only credentials, compact failure/stale
behavior, measured cost, and no source-service changes.

## Implementation Plan

1. Select one `Ready` family with the operator and freeze its approved fields.
2. Verify official API/schema, minimum read-only scope, rate limits, and privacy.
3. Audit any community template at an immutable commit and copy approved code
   locally; reject extension services or mutable runtime fetches.
4. For DNS, prefer totals/blocked percentage/bounded aggregate history and avoid
   raw family queries, clients, or full top-domain logs unless explicitly approved.
5. For UniFi, prefer gateway/AP/switch health and bounded counts; do not change
   controller state or expose topology/client identities without approval.
6. For Tailscale, prefer online/offline/update counts; redact names, owners, and
   addresses according to the matrix.
7. Set supported caches/timeouts and test unauthorized, stale, empty, partial,
   rate-limited, and unreachable responses.
8. Update matrix/docs and create separate tasks for other now-Ready families.

## Affected Files

- `compose/monitoring/glance/pages/network.yml`
- one family directory under `compose/monitoring/glance/widgets/network/`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` for names/scopes only
- `backlog/README.md` and justified follow-up task files

Do not modify DNS, UniFi, Tailscale, Traefik, firewall, source networks, or
Homepage.

## Testing Plan

- Run repository, Compose, Glance, YAML, and secret validation.
- Compare aggregates to the source UI without capturing private payloads.
- Test every failure/stale/privacy case and all target widths.
- Verify prohibited identifiers are absent from Git, logs, URLs, and screenshots.
- Measure incremental resource/network cost and confirm one-family scope.

## Rollback

Revert the family commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting update candidates. Do not delete credentials.

## Dependencies

Requires approved task 55, proven task-49 access, and one `Ready` source family.

## Risks

Network APIs contain sensitive household and topology data. Aggregate only,
scope credentials minimally, and render unknown rather than leaking diagnostics.

## Complexity

Medium for one source family; medium privacy risk.

## Suggested Order

Phase 3 after core Network. Additional families become separate tasks.
