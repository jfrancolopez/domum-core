# Task 83 - Expand Glance with safe available information

## Objective

Make Glance useful as a broad daily command center by exposing the repository's
already-available public and private-operational signals, while keeping secrets,
raw account history, device identities, and household routines out of the
dashboard by default.

## Background

The operator wants to start with a full dashboard and remove less useful items
after using it. The current eight-page Glance configuration already contains
public discovery, core monitors, Beszel summaries, Speedtest, aggregate AdGuard,
aggregate UniFi, and public media/news/community sources. The remaining safe gap
is that several enabled HTTP services are not visible in the operational view and
the existing sanitized Beszel adapter fields are not all rendered.

## Current Behavior

- All 26 enabled services are attached to `domum-proxy` on the production Pi.
- Hosting monitors only core infrastructure and three automation dependencies.
- The Beszel adapter returns load, disk, and temperature fields, but Hosting
  renders only CPU and memory.
- Personal integrations remain scaffolded or blocked on explicit credentials and
  field-policy decisions.

## Desired Behavior

- Hosting shows bounded HTTP reachability for enabled automation, productivity,
  and operations UIs using internal Docker checks and existing external links.
- Hosting renders available sanitized Beszel load, disk, and temperature values.
- Public pages remain broad and easy to prune by editing page YAML.
- Private-personal sources remain disabled until their explicit inputs and fields
  are approved.

## Implementation Plan

1. Export the documented `GLANCE_IMAGE` override through domum-core's Compose
   environment plumbing.
2. Add a broad but bounded Hosting service monitor for currently enabled HTTP
   services; omit non-HTTP data stores and disabled services.
3. Render already-sanitized Beszel load, disk, and temperature metrics when
   present, with no new adapter fields or host mounts.
4. Update the capability matrix and service documentation.
5. Validate Glance config, Compose, all smoke tests, and gitleaks.
6. Deploy through update/apply and remove unwanted sources after real use.

## Affected Files

- `bin/domum-core`
- `compose/monitoring/glance/pages/hosting.yml`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `backlog/README.md`
- `backlog/task-83-glance-safe-information-expansion.md`

## Testing Plan

- Run Bash syntax, Shellcheck, YAML lint, Glance validation, Compose rendering,
  existing smoke tests, and tracked-file gitleaks.
- Verify the new service URLs resolve through the `domum-proxy` network in the
  production Compose topology without printing private addresses.
- Confirm the adapter output remains sanitized and that absent metrics render no
  false values.
- Perform browser/mobile review on the Pi and remove noisy sources afterward.

## Rollback

Revert the page, plumbing, documentation, and matrix changes, then run the
normal `update` and `apply` path. No data, secret, or service state is modified
by the dashboard widgets.

## Dependencies

- Existing enabled services and `domum-proxy` network.
- Existing Glance/Beszel adapter and private access boundary.

## Risks

Static monitor lists can show a service as down if it is intentionally disabled
later. A broad page can become noisy or increase request volume; keep one-minute
checks limited to local endpoints and prune after observation. Operational
metrics remain visible only behind the existing LAN/Tailscale boundary.

## Complexity

Small.

## Suggested Order

Complete after task 82's Tailscale path fix and before adding credential-backed
personal integrations.

## Decisions and Rejected Alternatives

- Decision: begin with no-new-secret operational data and existing public feeds.
- Decision: use internal Docker service checks rather than external public DNS for
  monitor health.
- Decision: render only fields already sanitized by the Beszel adapter.
- Rejected: mount Docker, host, backup, or service data into Glance.
- Rejected: enable calendar, presence, media history, Steam, Spotify, or YouTube
  account data merely because the operator plans to prune it later; these require
  explicit field and credential boundaries first.
