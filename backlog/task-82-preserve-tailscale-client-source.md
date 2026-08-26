# Task 82 - Preserve Tailscale client source through Docker

## Objective

Make Glance reachable from trusted Tailscale clients while preserving the
LAN/Tailscale-only Traefik boundary and rejecting unrelated Docker clients.

## Background

A real Mac-to-Pi request forced to the Pi's Tailscale address still returned
HTTP 403 after Docker loaded `userland-proxy=false` and Glance had the correct
allowlist labels. Read-only inspection found the actual source rewrite in the
host firewall path: traffic arriving on `tailscale0` is marked by Tailscale,
Docker DNAT forwards published port 443 to Traefik's bridge address, and
Tailscale's `ts-postrouting` masquerade rule then replaces the client address.
Traefik therefore cannot match the client's `100.64.0.0/10` address.

The Pi advertises no subnet routes and is not an exit node. Its documented
Tailscale role is host remote access, not subnet routing.

## Current Behavior

- Tailscale preference `NoSNAT` was false before the repair.
- The firewall had a marked-traffic masquerade rule in `ts-postrouting` before
  the repair.
- Docker DNAT correctly forwards port 443 to Traefik, but that forwarding
  activates the Tailscale masquerade path.
- The live preference is now `NoSNAT=true`; the `ts-postrouting` chain is empty,
  and the Tailscale Mac request succeeds.
- DNS, Tailscale Serve, Docker daemon reload, Glance labels, and container
  health have been ruled out.

## Desired Behavior

- Domum-core converges `tailscale set --snat-subnet-routes=false` for its
  host-only Tailscale role.
- Checkup reports drift without printing addresses, routes, or device IDs.
- Traefik receives the real Tailscale client address and its existing exact
  allowlist admits it.
- LAN remains allowed and genuinely external clients remain denied.

## Implementation Plan

1. Add read-only exact-JSON helpers that check Tailscale's `NoSNAT` preference
   and confirm the node advertises no routes and offers no exit node.
2. Include `--snat-subnet-routes=false` in initial authentication guidance and
   converge it with `tailscale set` only on confirmed host-only nodes.
3. Add checkup health/warning/action output for the setting.
4. Update Tailscale, Glance, and recovery documentation with the reason and
   explicit unsupported subnet-router behavior.
5. Add a focused regression smoke test and run all repository validation.
6. After operator approval, apply only the Tailscale preference live, inspect
   the resulting sanitized preference/firewall state, and retest Mac, LAN, and
   external paths.

## Affected Files

- `bin/domum-core`
- `tests/tailscale-client-source-smoke.sh`
- `.github/workflows/validate.yml`
- `docs/services/tailscale.md`
- `docs/services/glance.md`
- `docs/glance-dashboard-architecture.md`
- `docs/glance-dashboard-audit.md`
- `docs/backups/disaster-recovery.md`
- `docs/getting-started/operator-ssh-access.md`
- `backlog/task-80-glance-tailscale-access-repair.md`
- `backlog/README.md`
- `backlog/task-82-preserve-tailscale-client-source.md`

## Testing Plan

- Test true, false, malformed, and unavailable Tailscale preference output.
- Run Bash syntax, Shellcheck, YAML lint, Compose rendering, existing tests,
  focused Tailscale smoke, and tracked-file gitleaks.
- On the Pi, verify only `NoSNAT`, advertised-route presence, exit-node role,
  and relevant rule behavior without recording addresses.
- From real clients, require Tailscale and LAN HTTP 200, external HTTP 403, and
  a working Homepage embed.

## Rollback

Run `sudo tailscale set --snat-subnet-routes=true`, then revert the repository
commit and deploy normally. This restores Tailscale's prior source-NAT behavior;
it does not modify containers, data, secrets, or tailnet authorization.

## Dependencies

- Existing host-managed Tailscale and Traefik deployment.
- No advertised subnet routes and no exit-node role on this Pi.
- Task 49's exact LAN/Tailscale Glance allowlist remains unchanged.

## Risks

Disabling SNAT is inappropriate for a subnet router whose destination networks
lack return routes to Tailscale clients. Domum-core does not support that role;
adding it later requires a separate routing design and must revisit this policy.

## Complexity

Small-medium.

## Suggested Order

Complete before any further allowlist changes or private Glance expansion.

## Decisions and Rejected Alternatives

- Decision: preserve the real client source by disabling unused subnet-route
  SNAT on this host-only Tailscale node.
- Decision: keep the existing exact LAN and Tailscale allowlist unchanged.
- Rejected: allow `172.19.0.1` or another Docker gateway, because unrelated
  containers can share that observed source and bypass the boundary.
- Rejected: trust forwarded headers; there is no authenticated upstream proxy
  supplying them and clients could spoof them.
- Rejected: add a client `/32`; masquerading removes that address before
  Traefik and the exception would not solve the forwarding path.
- Rejected: Tailscale Serve or another proxy layer; it adds provider/runtime
  state and does not preserve the custom-hostname TLS path as simply.
