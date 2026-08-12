# Task 69 - Add private CIDR plumbing for Glance access policy

## Objective

Add a local-only configuration path for the operator's LAN CIDR so task 49 can
apply a narrow Traefik IP allowlist to Glance without committing private network
topology or broad RFC1918 ranges.

## Background

The task-47 audit proved `dash` is publicly reachable through a direct CNAME to
Traefik. Traefik does not currently trust forwarded client headers, so its
observed remote address is not spoofable through the current direct path. The
approved task-48 access candidate is a Traefik IP allowlist for the actual LAN
CIDR and Tailscale CGNAT range.

`DOMUM_LAN_IP` is already a local-only host address but cannot represent all LAN
clients. Traefik file-provider YAML cannot safely consume an unexported local
value, and committing an actual CIDR would violate the dashboard privacy model.

## Why This Exists

Without this plumbing, task 49 must choose between an unsafe broad allowlist, a
single-host rule that locks out LAN clients, hand-edited host state that cannot
be recovered, or a different access architecture. None is acceptable.

## Current Behavior

- Glance is public at `dash.${DOMUM_DOMAIN}`.
- No Glance router access middleware exists.
- The current config example has `DOMUM_LAN_IP` but no LAN CIDR value.
- The CLI exports only known Compose environment variables.

## Desired Behavior

- A local-only `DOMUM_GLANCE_LAN_CIDR` value may be configured on the Pi and is
  never committed with its real value.
- Compose can render the Glance router access middleware using that value and a
  reviewed Tailscale range when task 49 is approved.
- Empty/malformed values fail safe: task 49 must not deploy a partially expanded
  allowlist or make Glance unreachable by accident.
- A rebuild is reproducible from Git plus the existing local config/recovery
  mechanism.

## Implementation Plan

1. Read `AGENTS.md`, task-47 audit, task-48 access decision gate, and task 49.
   Confirm the direct source-address path remains true before editing.
2. Add a commented `DOMUM_GLANCE_LAN_CIDR` example with documentation that it is
   a CIDR, local-only topology, and required only when private Glance access is
   enabled. Do not add a real CIDR to Git.
3. Extend only the existing CLI configuration loading/export mechanism so Compose
   receives this variable. Do not add a second environment file or secret store.
4. Add a bounded validation helper that accepts a single IPv4 CIDR and rejects
   blank, malformed, or multi-value input when private Glance access is enabled.
   If validation would require a dependency beyond existing Debian tools, stop
   and document the exact alternative.
5. Update CI dummy environment only if Compose rendering needs it. Do not make
   Glance require the variable until task 49 attaches the middleware.
6. Document configuration, validation, recovery, and rollback. Do not add a
   router middleware, change Glance access, or restart any service in this task.

## Affected Files

- `config/domum.conf.example`
- `bin/domum-core`
- `.github/workflows/validate.yml` only if its Compose environment needs a dummy
  value
- `docs/services/glance.md`
- `docs/reference/secrets.md` only if a privacy/configuration inventory note is
  needed
- `backlog/README.md` (status only after completion)

Do not modify Glance page YAML, Traefik routers/middlewares, DNS, firewall,
Tailscale policy, Homepage, source services, or live config values.

## Testing Plan

- Run all mandatory shell, shellcheck, YAML, Compose, and gitleaks checks.
- Test valid CIDR, blank, malformed, and multi-value inputs without printing the
  live LAN value.
- Confirm existing public-safe Glance rendering remains unchanged.
- Confirm a fresh host can leave the optional variable unset until task 49.

## Rollback

Revert the plumbing commit. It does not attach an access policy or change runtime
behavior, so no service restart or secret deletion is required.

## Dependencies

Requires approved task 48. Blocks task 49's Traefik IP-allowlist option. If the
operator chooses a different access mechanism, mark this task not needed with
the recorded reason.

## Risks

Weak validation could lock out the operator or widen the allowlist. Keep the
variable optional until task 49, validate before interpolation, and never commit
the real CIDR.

## Complexity

Small configuration/validation change; low runtime risk.

## Suggested Order

Run after task 48 and before task 49 if the operator approves the Traefik
IP-allowlist design.
