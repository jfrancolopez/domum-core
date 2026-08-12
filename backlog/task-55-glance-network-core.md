# Task 55 — Build the core Glance Network page

## Objective

Build the first private Network page around WAN quality, Speedtest Tracker, and
a small local latency/outage summary. DNS, UniFi, and Tailscale belong to task
55. Protect identifiers and avoid turning transient latency into false alerts.

## Background

The operator selected deep private network visibility and faster operational
data. The exact gateway, DNS, UniFi, Tailscale, outage-history, and public-IP
sources come from task 47. Speedtest Tracker is already deployed in this repo.
The desired dashboard access is LAN/Tailscale only, and task 49 must prove the
boundary and classify individual fields before this page may expose them.

## Current Behavior

Glance has no network page. Homepage has high-level status and Speedtest metrics,
which must not simply be copied. Existing Glance monitors cache for one minute,
but there is no latency baseline, historical network context, or privacy policy.

## Desired Behavior

Network answers whether the internet is working normally, how performance has
changed, whether DNS/VPN/network devices need attention, and which specialist UI
contains detail. It exposes only operator-approved identifiers and degrades to
unknown without leaking credentials or raw payloads.

## Implementation Plan

1. Reconfirm LAN/Tailscale-only acceptance from task 49 before rendering public
   IP, internal IP, Tailscale device name, client identity, or topology.
2. Implement Speedtest Tracker latest and history from its documented API. Show
   download, upload, ping, jitter, packet loss, timestamp, and a bounded real
   trend only where fields exist. Audit any community template at an immutable
   commit and copy approved code locally.
3. Add WAN status, ISP, approximate location, gateway uptime, and WAN RX/TX only
   from approved structured sources. Respect the operator's public-IP decision.
4. Use a deliberately small probe set for local service latency. Establish a
   baseline from multiple samples; warning means sustained increase, critical
   means timeout/outage, not one slow response. SSH is excluded unless task 48
   specifically approved a read-only design without private-key exposure.
5. Set request timeouts and cache targets where supported by the pinned Glance
   version. Record fixed upstream behavior separately. One-minute cache is
   allowed for small local status calls; history should normally use 5-15m.
6. Test outage, partial API, rate limit, stale history, and slow-response states.
7. Update capability/privacy matrices and obtain approval before task 56.

## Affected Files

- `compose/monitoring/glance/pages/network.yml`
- approved templates under `compose/monitoring/glance/widgets/network/`
- approved shared CSS/assets only
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` for names/scopes only
- `backlog/README.md` (status only)

Do not modify Speedtest Tracker, DNS, UniFi, Tailscale, Traefik, firewall, Docker
networks, Homepage, or any source service.

## Testing Plan

- Run repository, Compose, Glance, YAML, and secret validation.
- Cross-check metrics and units against source applications at matching times.
- Verify public/internal identifiers are absent where prohibited.
- Test API timeout, stale cache, partial history, empty device list, and rate
  limit behavior.
- Validate thresholds with sustained samples rather than single requests.
- Test all target widths and measure page/network/container resource cost.
- Confirm Homepage is unchanged and its existing Speedtest widget still works.

## Rollback

Revert the core Network commit, update the checkout, then run a supervised
full-stack apply and checkup after inspecting update candidates. Credentials may
remain unused; never delete or overwrite them during rollback.

## Dependencies

Requires approved task 54, proven private access boundary, and `Ready` core
Network rows. New probes, adapters, agents, or source changes need separate
approval.

## Risks

This page has high privacy risk and can create API load. Raw DNS/Tailscale/UniFi
data may reveal family behavior and topology. Use summaries, caching, strict
limits, read-only scopes, and explicit unknown states.

## Complexity

Medium configuration and integration work; medium privacy/operational risk.

## Suggested Order

Phase 3 after external Hosting.
