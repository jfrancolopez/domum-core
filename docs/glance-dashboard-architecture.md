# Glance Dashboard Architecture

## Purpose

Glance at `https://dash.${DOMUM_DOMAIN}` is the deep personal information
dashboard. Homepage remains the service launcher and fast operational overview.
Beszel, Plex, Speedtest Tracker, and other specialist applications remain the
source of detailed investigation; Glance summarizes and links to them.

The running release is Glance `v0.8.5`. It supports ordered pages with up to
three columns, `$include`, native widgets, and server-side `custom-api`
templates. It does not support inventing widget types from YAML files. See the
[v0.8.5 configuration documentation](https://github.com/glanceapp/glance/blob/v0.8.5/docs/configuration.md).

## Access and Privacy

`dash` is intended to be LAN and Tailscale-only. The repository now implements
the Glance-only Traefik allowlist for the approved LAN CIDR and Tailscale range;
the audit records successful trusted-client requests and denied external and
untrusted-container requests. Final browser and performance acceptance remains
open. Do not add new private-personal integrations until that acceptance is
closed.

Task 49 attached the approved Traefik allowlist and its Pi audit passed LAN,
Tailscale, external mobile-data denial, and untrusted-container checks. Docker
`userland-proxy=false` is required so Traefik sees real Tailscale client sources.
The remaining task-47 acceptance work is browser coverage, responsive evidence,
request/byte measurement, and resource measurement for the current pages.

| Level | Meaning | Examples |
|---|---|---|
| Public-safe | Safe if accidentally visible publicly | Clock, weather, public RSS, public project releases |
| Private-operational | Reveals service state or limited topology | Service monitor, backup age, host alias, DNS summary |
| Private-personal | Reveals household behavior or identity | Calendar titles, WAN IP, media activity, Steam friends |
| Secret | Authorizes a source or embeds a private URL | API token, password, private ICS URL |

Secrets stay in `/etc/domum-core/secrets`. Task 50 provides narrowly scoped,
optional Glance secret plumbing. A value, token-bearing URL, or account ID never
belongs in Git, page YAML, screenshots, logs, or this documentation.

### Access Decision Gate

Task 49 selected and implemented one exact Glance-only allowlist. The recorded
Pi checks cover the trusted proxy chain and real client source addresses without
committing address values; final browser/performance evidence remains with the
program acceptance tasks.

| Option | Decision | Reason |
|---|---|---|
| Traefik IP allowlist for approved LAN and tailnet ranges | Selected | Repository-controlled Glance-only middleware using the local-only LAN CIDR and Tailscale CGNAT range; task 49 proves direct client addresses and external denial |
| Cloudflare Access alone | Rejected | Login does not meet the chosen network-restriction outcome by itself |
| Host firewall or router ACL | Deferred | Outside the Glance scope; needs a separate operator-approved network change |
| Tailscale ACL/Serve-only path | Deferred | Existing DNS/proxy and client behavior are not yet audited |
| Split-horizon/private DNS | Deferred | Requires DNS design outside this dashboard program |

The required result is direct and Homepage-embedded `dash` access from trusted
LAN and Tailscale clients, with an external non-tailnet client denied before
Glance content is served. A public certificate or public DNS record is not
evidence of an acceptable access boundary.

## Page Map

| Page | Purpose | First approved scope |
|---|---|---|
| Home | Time, weather, search, compact daily context | Native clock/weather/search/bookmarks/RSS; private calendar and presence wait for task 75 |
| Hosting | Accurate host and service summaries | Native monitor/releases plus the reviewed Beszel summary adapter; backup and Healthchecks detail wait for task 74 |
| Network | Internet quality and selected network context | Speedtest Tracker, aggregate AdGuard stats, aggregate UniFi health, and fixed reachability checks; identity/topology remain excluded |
| Media | Playback and discovery | Public discovery now; Plex/Tautulli waits for task 76 |
| Games | Public gaming discovery and optional personal Steam information | Steam Specials, Top Sellers, and public feeds now; profile, recently played, wishlist, friends, and Twitch wait for task 77 |
| News | Curated infrastructure, security, self-hosting, Linux, and AI briefing | Native RSS, releases, and selected public community signals |
| Social | Small public community/creator set | Hacker News, Lobsters, selected forums, YouTube, GitHub, and direct links; Reddit remains unresolved |
| Technology | Public engineering and stack briefing | Native releases, RSS, videos, and bounded Domum Core activity |

Pages remain separate even when related: Hosting owns systems, Network owns
connectivity, News owns briefing, and Social owns deliberately selected
communities. Do not show empty pages or duplicate Homepage's launcher cards.

## Information and Responsive Design

- Build mobile hierarchy first. A page must remain useful at 390 px without
  horizontal overflow.
- Use at most three Glance columns. On dense desktop pages, the first column is
  context/navigation, the second is primary information, and the third is
  supporting detail or forecast.
- Compare dense-NOC and media-rich subtle-cyberpunk prototypes in task 51 using
  real existing public-safe widgets. Select one before adding broad CSS.
- Use color only for real state: healthy green/cyan, warning amber, critical red,
  offline gray/red, and unknown muted. Never color static or invented values.
- Images are bounded: posters/thumbnails are appropriate for Media, Games, and
  selected feeds; operational pages remain text-forward.
- A widget failure must be compact and identifiable. Omit an unavailable optional
  widget rather than retaining a broken image, placeholder card, or stale green
  state.

## Source and Template Rules

1. Prefer a native Glance widget.
2. Then use a reviewed in-repo `custom-api` template, copied with source URL and
   immutable commit/version noted in the capability matrix.
3. Use an iframe only for a bounded specialist view that works on mobile.
4. Reject extension containers, raw Docker sockets, SSH-key checks, arbitrary
   JavaScript, and adapters unless a separate approved task proves the gap.

`custom-api` uses server-side Go templates. It is not a new-widget registration
mechanism. Do not use `allow-potentially-dangerous-html`, mutable remote YAML,
or downloaded scripts at runtime.

## Data Sources and Credentials

| Source family | Planned use | Credential decision |
|---|---|---|
| Open-Meteo via native weather | Durham weather in Fahrenheit | None |
| IANA time zones via native clock | Durham, Nuevo Laredo, San Jose | None |
| Google calendar/ICS or CalDAV | Seven upcoming titled events | Read-only ICS selected; private-personal |
| Beszel | Host summary only | Reviewed local adapter with dedicated read-only credential |
| Speedtest Tracker | Latest result and bounded history | Read-only `results:read` API token |
| AdGuard Home | Aggregate DNS stats | Operator-approved credential for aggregate stats only; top domains and raw queries excluded |
| Plex/Tautulli | Playback and history | Plex-first; read API/token model must be audited |
| Sonarr/Radarr/Immich | Releases, queues, library statistics | Installed service and version-matched API required |
| Steam | Store specials and personal library/profile | Public Specials endpoint implemented; personal data needs API key and private access |
| GitHub/Reddit/YouTube/RSS | Public news and social content | Selected public sources implemented; Reddit remains deferred after rate-limit/forbidden responses |

Potential future secret names/scopes are inventory only, not creation requests:
calendar read feed, Steam read key, Plex read token, Tautulli key, Sonarr/Radarr
keys, Immich key, Speedtest Tracker `results:read` token, Reddit app credentials,
approved because their least-privilege model is not yet verified.

| Future secret or private value | Scope | Owner | Recovery decision |
|---|---|---|---|
| Calendar read feed/account | Read-only selected calendar(s) | Operator | Task 50 records file name and recovery-pack treatment |
| Steam API key and account identifier | Read-only selected profile | Operator | Task 50 records file name; identifier is private-personal |
| Plex/Tautulli/Sonarr/Radarr/Immich keys | Read-only selected API | Operator | Create only after source/version review |
| Speedtest Tracker token | `results:read` only | Operator | Create only for approved Network rows |
| Reddit/GitHub/Twitch credentials | Minimal public/read-only scope | Operator | Optional; use only for rate-limit or selected-content need |

AdGuard aggregate statistics and a dedicated UniFi direct API key have operator
approval with bounded fields. The UniFi aggregate-health widget is implemented;
live credential/data/failure validation remains a Pi-only acceptance item. No
Tailscale device token or source-service credential is authorized beyond the
specific matrix rows.

## Cache and Resource Budget

| Class | Target | Limits |
|---|---:|---|
| Small local availability/latency | 1 minute | Small fixed monitor set only |
| Host, network, playback summaries | 5 minutes | One source family per page phase |
| Calendar, queues, releases, discovery | 15 minutes | Bounded lists and images |
| Social/video aggregation | 1 hour | Selected communities/creators only |
| RSS and software releases | 6 hours | Limit 8-15 entries per widget |
| Slow inventory/statistics | 24 hours | No repeated polling |

Glance fetches data server-side on page use and caches in memory; cache age is
not a promise of browser-side real-time updates. Config reload clears its cache.
Every implementation task records actual request count, bytes, and container
CPU/RAM delta against the prior phase.

## Phase Acceptance Measurements

Before a page advances, measure and record:

- HTTP/page-load result and request/byte count for its changed page.
- Glance CPU and RAM at idle and during page load, compared with the prior phase.
- Successful, unavailable, unauthorized, malformed, and slow-source behavior
  for every changed API widget.
- Layout at 1920, 1440, 1024, 768, 430, and 390 px, including direct and
  Homepage-embedded views where applicable.
- Secret scan, rendered HTML/log review, image failure behavior, and link check.

Task 50 added version-matched static/startup validation. A running container is
still evidence only that its active configuration parsed; it is not proof that
future include trees or remote widgets work.

## Failure and Recovery

- Invalid configuration must retain the last known-good config where the running
  release supports reload; the version-matched validation check runs before
  relying on a configuration change.
- The current validated modular dashboard is the rollback point. Revert one
  approved phase at a time rather than restoring the historical two-page draft.
- Git recreates all config, templates, assets, and documentation. Only secret
  files require recovery through the existing secret/recovery-pack mechanism.
- Revert one approved phase at a time, recreate only Glance where possible, and
  never delete runtime data or secrets.
