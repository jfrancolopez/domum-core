# Task 49 — Enforce the private Glance access boundary

## Objective

Make the operator's chosen LAN/Tailscale-only Glance access boundary true and
provable before any private calendar, network identifiers, media activity, or
gaming account data is rendered. Change only the Glance access path selected and
approved in task 48; do not alter unrelated services.

## Background

Glance is routed at `https://glance.ladomum.com` through Traefik. The current
Glance Compose labels do not themselves prove authentication or source-network
restriction. Homepage also embeds Glance through the existing
`glanceEmbedHeaders` middleware and must keep working without any Homepage edit.
Task 47 records actual LAN, Tailscale, and external reachability. Task 48 compares
compatible enforcement mechanisms and names the exact approved files/behavior.

The desired outcome is reachability from trusted LAN and Tailscale clients and
denial from a genuinely external non-tailnet client. A public DNS name or TLS
certificate does not prove public reachability, and a successful browser cookie
does not prove network restriction.

## Current Behavior

Use task 47's verified audit only. If external reachability was not tested, this
task cannot proceed. If task 48 did not select one mechanism and enumerate exact
files, stop and return to task 48 rather than improvising auth, DNS, firewall,
Cloudflare, or trusted-proxy behavior.

## Desired Behavior

- Trusted LAN and Tailscale clients load direct Glance and the Homepage embed.
- External non-tailnet clients are denied before Glance content is returned.
- Denials do not reveal dashboard content or internal topology.
- Existing Homepage, Traefik routes, TLS, and unrelated services are unchanged.
- The mechanism and disaster-recovery setup are fully Git/documented except for
  secret values or provider-side state already governed elsewhere.

## Implementation Plan

1. Reproduce task 47's reachability tests and inspect the task-48 decision,
   forwarded-client-IP trust chain, LAN/tailnet ranges, Cloudflare path, and
   Homepage iframe behavior. Never print headers, cookies, tokens, or addresses
   into tracked output.
2. Present the exact diff and rollback to the operator immediately before any
   runtime change. This is the mandatory approval gate for authentication,
   proxy, DNS, or firewall behavior required by `AGENTS.md` and the project
   prompt.
3. Implement only the selected narrow mechanism. Prefer repository-controlled
   Glance/Traefik policy that survives rebuild. Do not edit provider-side DNS,
   Cloudflare Access, host firewall, or Tailscale ACLs unless task 48 selected it
   and the operator separately authorizes that exact change.
4. If credentials are part of the approved defense-in-depth design, keep values
   under `/etc/domum-core/secrets`, use read-only mounts/environment references,
   and inventory names/scopes only. Network restriction remains the required
   outcome; login alone is not a substitute unless the operator changes policy.
5. Validate configuration offline, then use the normal Git deployment path in a
   maintenance window. `domum-core apply` is full-stack, not service-targeted;
   inspect update candidates first and monitor unrelated enabled services.
6. Test direct and embedded Glance from LAN and Tailscale, denial from external
   non-tailnet, TLS, redirects, forwarded headers, and container logs. Confirm no
   allowlist bypass through spoofable headers or an alternate router/port.
7. Run `sudo domum-core checkup`, document the exact recovery/rebuild procedure,
   and obtain operator acceptance before task 50.

## Affected Files

- exact Glance access-control files selected and named by task 48, limited to
  `compose/monitoring/glance.yml` and/or Glance-specific files under
  `compose/proxy/traefik/dynamic/`
- `docs/services/glance.md`
- `docs/dashboard-architecture.md`
- `docs/reference/secrets.md` only if credential names are added
- `backlog/README.md` (status only)

Do not edit Homepage, global DNS/firewall/Tailscale/Cloudflare policy, or an
unrelated router/middleware without a new explicit operator approval and task.

## Testing Plan

- Run all `AGENTS.md` checks, yamllint, Compose rendering, and gitleaks.
- Test from three genuinely different paths: LAN, Tailscale, and external
  non-tailnet. Record result and method without addresses/private content.
- Test direct and Homepage-embedded Glance and ensure unrelated HTTPS services
  still route normally.
- Inspect Traefik and Glance logs for errors and accidental sensitive output.
- Confirm a fresh-rebuild operator can recreate the policy from Git plus the
  existing secret/recovery mechanism.

## Rollback

Revert the task commit, deploy through `sudo domum-core update`, then perform a
supervised full-stack `sudo domum-core apply` and `sudo domum-core checkup`.
Never delete or overwrite credentials. Re-test all three network paths; rollback
may restore external exposure, so keep private widgets disabled until fixed.

## Dependencies

Requires completed task 47, an operator-approved exact task-48 access design,
and task 69 if the selected design is Traefik IP allowlisting. Blocks task 50
and every private widget.

## Risks

Incorrect trusted-proxy or allowlist behavior can either expose private data or
lock out trusted users. A full-stack apply can reconcile unrelated services.
Use a maintenance window, exact rollback, independent external testing, and no
private content until acceptance.

## Complexity

Medium repository and Pi networking validation; medium operational risk.

## Suggested Order

Phase 1, before modularization or private credential plumbing.
