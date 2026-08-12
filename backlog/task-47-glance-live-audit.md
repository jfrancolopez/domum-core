# Task 47 — Audit live Glance and data sources

## Objective

Produce a sanitized, read-only baseline of the production Glance deployment,
its actual access boundary, available data sources, performance, and operator
preferences. Do not change configuration or restart any service in this task.

## Background

Glance already runs at `https://glance.ladomum.com`, but this repository checkout
is explicitly not the production host. Git shows `glanceapp/glance:latest`, a
single 145-line config, two pages, a read-only config mount, and no credential
plumbing. The exact running image/version, page behavior, logs, reachability,
and connected services are unknown. The operator wants seven eventual pages
and chose LAN/Tailscale-only access, private calendar content, API-first host
data, deep network visibility, and a faster operational-data bias.

Read `AGENTS.md` and `backlog/glance-dashboard-program.md` completely first.

## Current Behavior

- Git defines Domum and Technology pages with search, bookmarks, monitors,
  RSS, videos, and releases.
- Current docs describe Glance as a limited overview, not the proposed central
  information dashboard.
- Traefik labels expose the hostname but do not themselves prove LAN/Tailscale
  restriction or authentication.
- Glance has no Docker socket or host mount and must remain that way.
- Upstream Glance generally fetches on page load and serves cached responses;
  it is not safe to assume browser-side periodic refresh.

## Desired Behavior

A tracked, sanitized audit report contains enough facts for another model to
design the capability matrix without rediscovery. Unknowns stay explicitly
unknown. No token, private URL, account ID, internal IP, public IP, event title,
media title, username, payload, or secret-derived value enters the report.

## Implementation Plan

1. On the repository checkout, record current commit, relevant files, and
   Compose/catalog relationships. Do not read ignored `data/` or secret files.
2. On the Pi, use read-only commands to record the Glance image reference,
   image ID/digest, reported version or build metadata, container health/state,
   mounted paths, networks, and sanitized environment variable names only.
3. Record documented config-reload capabilities for the running version and mark
   live reload behavior untested. The harmless live edit belongs to task 51.
4. Test reachability from LAN, Tailscale, and a genuinely external non-tailnet
   client. Record only reachable/not reachable and protection type. Stop and
   report if private Glance is externally reachable before inspecting personal
   integrations.
5. Capture a baseline screenshot set and browser behavior at 1920, 1440, 1024,
   768, 430, and 390 px. Sanitize screenshots before tracking; prefer recording
   findings without committing screenshots containing private information.
6. Measure Glance container idle/load CPU and RAM and one page-load request/byte
   count. Record method, sample duration, and limitations.
7. Inventory hosts by role and API availability: domum-core, domum-core-media,
   Unraid, Proxmox, Talos/Kubernetes, cloud, and other Linux. Record only aliases
   approved for Git, not addresses.
8. Inventory service/API presence and host ownership for Beszel, Speedtest
   Tracker, DNS, UniFi, Tailscale, Uptime Kuma, media services, gaming APIs,
   calendars, GitHub, and public feed sources. Record authentication mechanism
   and read-only-account availability without values.
9. Ask the remaining exact preference questions not resolved by the program
   charter: page ranking after Home/Hosting/Network, temperature units,
   secondary location content, calendar groups/event count, public-IP display,
   allowed private identifiers, Steam visibility, media privacy, news sources
   and exclusions, Reddit communities, creators/repos, and image limits.
10. Add `docs/glance-dashboard-audit.md` and link it from `docs/README.md`.
    Separate verified facts, operator decisions, unknowns, and Pi tests not run.

## Affected Files

- `docs/glance-dashboard-audit.md` (new, sanitized facts only)
- `docs/README.md`
- `backlog/README.md` (status only after completion)

Do not modify Compose, Glance YAML, Homepage, Traefik, config examples, secrets,
source services, DNS, firewall, or authentication.

## Testing Plan

- Review the report line by line for identifiers and secret material.
- Run `git diff --check` and repository Markdown/link checks if present.
- Run gitleaks against the worktree.
- Verify `git diff --name-only` contains only the three allowed documentation
  paths.
- Have the operator confirm the sanitized inventory and unresolved questions.

## Rollback

Revert the documentation commit. No runtime rollback exists because this task
must not alter runtime state.

## Dependencies

First task in the Glance program. No implementation task may bypass it.

## Risks

The main risk is leaking secrets or private topology while documenting the
audit. Capture names and capabilities, not values or payloads. Runtime commands
must be read-only. Stop if access-boundary testing shows public exposure.

## Complexity

Medium research and operator coordination; low operational risk.

## Suggested Order

Phase 0, first. Obtain operator approval of the report before task 48.
