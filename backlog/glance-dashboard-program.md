# Glance Daily-Dashboard Program

## Purpose

Turn the existing Glance service into the operator's private, Git-recoverable
daily dashboard for home, infrastructure, networking, media, gaming, news, and
curated social information. The result should be visually distinctive and
useful across multiple computers without becoming a duplicate of Homepage or a
replacement for specialist tools such as Beszel, Grafana, Plex, or UniFi.

This charter is planning only. It does not authorize changes to production
services, authentication, DNS, firewall rules, source applications, or
Homepage. Every numbered task is a separate implementation and approval gate.

## Repository Facts at Program Creation

- The tracked service is `compose/monitoring/glance.yml` and is disabled by
  default through `ENABLE_GLANCE`.
- The tracked dashboard is a single 145-line file at
  `compose/monitoring/glance/glance.yaml` with two pages: Domum and Technology.
- The Compose image is currently `glanceapp/glance:latest`; the exact running
  production version was not available from this non-production checkout.
- The config directory is mounted read-only at `/app/config`.
- Glance has no Docker socket, host filesystem mount, runtime database, or
  credential environment file.
- Current documentation deliberately describes Glance as a limited daily
  overview. This program expands that role and must update
  `docs/dashboard-architecture.md` and `docs/services/glance.md` deliberately.
- Homepage embeds Glance and links to it. Homepage is approved and out of scope.
- The Glance Traefik router does not visibly declare authentication or an IP
  allowlist in its Compose labels. The operator's desired access boundary is
  LAN and Tailscale only; task 47 must establish actual reachability before any
  personal widget is enabled.
- Ignored runtime keys exist under service `data/` directories. They were not
  read and are not tracked. No task may inspect, copy, print, or repurpose them.

## Operator Decisions

- Build seven pages in phases: Home, Hosting, Network, Media, Games, News,
  Social. Do not merge News and Social initially.
- First useful release is the foundation followed by Home; later pages require
  approval one at a time.
- Steam basics come first. Exact profile visibility, identifier storage, and
  optional widgets remain audit inputs; never request a password.
- Inventory media services and hosts before designing media widgets.
- Prefer existing read-only APIs and Beszel over SSH, scraping, Docker socket
  access, or new agents.
- Build a deep private Network page. Public IP and other identifiers remain
  per-widget privacy decisions, not implied permission.
- Durham, North Carolina is the primary weather location. Secondary clocks or
  weather may cover Laredo, Nuevo Laredo, and San Jose after exact needs are
  recorded. Default timezone remains `America/New_York` until changed by the
  operator. Temperature units remain unresolved.
- A full private calendar is desired, but it is blocked until the access
  boundary is proven. Calendar credentials or private feed URLs never enter
  Git.
- News should be a broad daily briefing. Exact categories, sources, exclusions,
  Reddit communities, and thumbnail policy remain task 47 inputs.
- Social content uses public, curated feeds and documented public APIs only.
- Visual direction should compare dense NOC and media-rich subtle cyberpunk
  treatments before selecting one. Preserve useful Dracula/Domum continuity,
  but do not let the result look generic.
- Operational data may refresh faster than feeds, while remaining within a
  measured Raspberry Pi budget.
- This session creates backlog only. No dashboard implementation is authorized.
- Dynacat remains an optional, isolated experiment after Glance is complete.

## Product Boundaries

### Homepage owns

- Complete service directory and launcher.
- Fast high-level status and short service summaries.
- Main operational portal and existing approved layout.

### Glance owns

- Daily context, search, calendar, weather, and time progress.
- Curated historical summaries and trends sourced from existing APIs.
- Detailed infrastructure and network context without cloning specialist UIs.
- Media activity and discovery, personal gaming information, news, and social
  feeds.
- Rich lists, posters, bars, lightweight SVG, status colors, and meaningful
  contextual links.

A service may appear in both only when Glance provides materially deeper or
more contextual information. Do not change any Homepage file in this program.

## Technical Constraints

- Git remains authoritative. Keep Glance files under the existing
  `compose/monitoring/glance/` directory unless task 48 records a concrete
  repository reason to do otherwise.
- Secrets remain under `/etc/domum-core/secrets`, enter the container through
  narrowly scoped read-only Compose plumbing, and are inventoried without
  values in `docs/reference/secrets.md`. Never commit a populated `.env` file.
- Use only syntax supported by the exact pinned/running Glance version.
- Upstream Glance fetches widget data when a page is loaded and serves cached
  responses; it does not generally poll every widget continuously in the
  browser. Do not promise near-real-time dynamic updates without proving the
  installed version and mechanism.
- Prefer native widgets, then reviewed in-repo `custom-api` templates. Use an
  iframe only when it adds clear value and behaves safely on mobile. Extension
  services and adapters require a separate explicit operator approval.
- Never mount the raw Docker socket or host root filesystem into Glance.
- Never alter source services merely to satisfy a widget.
- Never invent APIs, sample data, fake values, unsupported graphs, or success.
- Do not add Prometheus, Grafana, Elasticsearch, large JavaScript libraries, or
  another monitoring stack.
- External inspiration is design input only. Do not copy a complete config.

## Community-Widget Gate

Before copying any community widget, record in the capability matrix:

- upstream repository URL and immutable commit reviewed;
- supported Glance version and data-source API version;
- all request URLs, headers, identifiers, credentials, and subrequests;
- template HTML escaping/injection behavior and any JavaScript;
- shell commands or extension services, which are rejected by default;
- timeout, cache, rate-limit, image, and failure behavior;
- maintenance status, license, privacy exposure, and resource impact.

Copy approved templates into the repository with provenance comments. Never
fetch mutable remote YAML or execute downloaded scripts at runtime.

## Capability Matrix Contract

Task 48 creates and later tasks maintain one tracked matrix with these columns:

| Widget | Page | Data source | Native/custom | Credential | Refresh/cache | Privacy | Resource | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|

Allowed status values are `Ready`, `Needs credential`, `Needs service`, `Needs
clarification`, `Unsupported`, and `Not recommended`. No implementation task
starts with unresolved `Needs clarification` rows in its scope.

Every visualization is also classified as native Glance, reviewed community
template, local custom API template, iframe, or not safely supported.

## Default Cache Budget

These are planning defaults, not claims about unsupported background refresh:

| Data class | Initial cache target |
|---|---:|
| Critical availability and local latency | 1 minute |
| Host, container, network, playback state | 5 minutes |
| Calendars, queues, releases, discovery | 15 minutes |
| Social/video aggregation | 1 hour |
| News and software releases | 6 hours |
| Slow-changing inventory/statistics | 24 hours |

Each page task must justify exceptions and cap list/image counts. One-minute
caching is reserved for small local requests; it is not the default.

## Required Page Sequence

1. Phase 0: sanitized live audit and capability architecture.
2. Phase 1: enforce private access, pin/validate runtime, then modularize visuals.
3. Phase 2: Home.
4. Phase 3: core/external Hosting, then core/deep Network.
5. Phase 4: core Media, then optional approved media sources.
6. Phase 5: Games.
7. Phase 6: News, Social, visual polish, hardening, and recovery proof.
8. Optional: assess extra Work/Code/Utilities pages and a future Dynacat test.

## Per-Task Completion Gate

Repository checks:

```bash
bash -n bin/domum-core bin/domum-core-backup install.sh
shellcheck bin/domum bin/domum-core bin/domum-core-backup install.sh
yamllint -c .yamllint.yml .
tests/catalog-consistency-smoke.sh
```

Run Compose rendering exactly as CI does when Compose files change. Run the
version-matched Glance validation introduced by task 50 for every config change.

Pi-only acceptance, never claimed from another checkout:

1. Deploy through Git, `sudo domum-core update`, supervised full-stack
   `sudo domum-core apply`, and `sudo domum-core checkup`. The CLI has no
   service-targeted apply; inspect pending candidates and use a maintenance
   window because unrelated enabled services may be reconciled.
2. Confirm Glance accepts and reloads the full include tree.
3. Inspect Glance logs without printing headers, tokens, or private payloads.
4. Test every changed widget against live data and a deliberate failure path.
5. Capture sanitized screenshots at 1920, 1440, 1024, 768, 430, and 390 px.
6. Check navigation, links, image loading, fallback states, and overflow.
7. Verify no secret appears in Git, rendered HTML, logs, or screenshots.
8. Measure container CPU/RAM and page/network cost against the previous phase.
9. Ask the operator to approve the next phase.

## Rejected Alternatives

- Big-bang seven-page implementation: rejected because broken APIs, leaked
  secrets, and unusable density would be difficult to isolate and roll back.
- Replace Glance with Dynacat now: rejected because Glance is installed, has the
  larger ecosystem, and provides the stable migration baseline.
- Copy inspiration configs wholesale: rejected because their hosts, APIs,
  credentials, versions, privacy model, and performance budgets differ.
- Make Glance another service launcher: rejected because Homepage already owns
  that role.
- Use Glance as Grafana: rejected because historical APIs may be summarized, but
  unsupported charting must not be invented.
- Add adapters preemptively: rejected because an adapter is another maintained
  service and requires a specific proven data gap plus separate approval.

## Program Rollback

Each phase is one logical commit or a small documented commit series. Revert
only the current phase, deploy through the normal update/apply flow, and retain
the last approved page set. Never use `docker compose down`, delete config or
data, or overwrite secret files. The original two-page config remains available
in Git history throughout the program.
