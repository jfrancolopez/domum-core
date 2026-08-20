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

`dash` is currently externally reachable. Until task 49 proves LAN and
Tailscale-only access, only public-safe widgets may be rendered. Do not add
calendar events, WAN IP, internal aliases, device names, media activity, Steam
identity/friends, or private feed URLs.

Task 49 has attached the approved Traefik allowlist and passed LAN, Tailscale,
external mobile-data denial, and untrusted-container checks. Docker
`userland-proxy=false` is required so Traefik sees real Tailscale client sources.
Before rendering private widgets, the first implementation task must still
perform a browser check for the direct dashboard and Homepage embed.

| Level | Meaning | Examples |
|---|---|---|
| Public-safe | Safe if accidentally visible publicly | Clock, weather, public RSS, public project releases |
| Private-operational | Reveals service state or limited topology | Service monitor, backup age, host alias, DNS summary |
| Private-personal | Reveals household behavior or identity | Calendar titles, WAN IP, media activity, Steam friends |
| Secret | Authorizes a source or embeds a private URL | API token, password, private ICS URL |

Secrets stay in `/etc/domum-core/secrets`. Task 50 must provide narrowly scoped,
optional Glance secret plumbing. A value, token-bearing URL, or account ID never
belongs in Git, page YAML, screenshots, logs, or this documentation.

### Access Decision Gate

Task 49 must select and present one exact implementation before any proxy,
authentication, DNS, firewall, or Tailscale change. It must test the trusted
proxy chain and real client source addresses without committing address values.

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
| Home | Time, weather, search, compact daily context | Native clock/weather/search/bookmarks/RSS; calendar events wait for task 49 |
| Hosting | Accurate host and service summaries | Native monitor and releases; Beszel only after its read API is verified |
| Network | Internet quality and selected network context | Wait for task 49; Speedtest Tracker is the first candidate |
| Media | Playback and discovery | Plex-first, after media-host inventory and read API review |
| Games | Personal Steam information and discovery | Steam specials, profile, recently played, wishlist, allowlisted friends only after review |
| News | Curated infrastructure, security, self-hosting, Linux, and AI briefing | Native RSS, Hacker News, Lobsters, releases |
| Social | Small public community/creator set | Reddit, YouTube, GitHub, and public RSS only after source selection |

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
| Google calendar/ICS or CalDAV | Seven upcoming titled events | Provider and read-only mechanism unresolved; private-personal |
| Beszel | Host summary only | API/auth/version must be audited |
| Speedtest Tracker | Latest result and bounded history | Read-only API token, if its documented API is enabled |
| AdGuard Home | Aggregate DNS stats | Existing admin credentials must not be reused without explicit approval |
| Plex/Tautulli | Playback and history | Plex-first; read API/token model must be audited |
| Sonarr/Radarr/Immich | Releases, queues, library statistics | Installed service and version-matched API required |
| Steam | Store specials and personal library/profile | Store endpoint needs review; personal data needs API key and private access |
| GitHub/Reddit/YouTube/RSS | Public news and social content | Token optional only when documented rate limits require one |

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

No existing AdGuard, Tailscale, UniFi, or source-service credential may be
reused until the operator approves the exact least-privilege approach. For UniFi,
the approved direction is a dedicated direct API key with read-only monitoring
scope, pending live endpoint/schema verification before any widget renders it.

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

Task 50 must add version-matched static/startup validation. Until then, a running
container is evidence only that its active configuration parsed; it is not proof
that future include trees or remote widgets work.

## Failure and Recovery

- Invalid configuration must retain the last known-good config where the running
  release supports reload; task 50 adds a version-matched validation check before
  relying on it.
- The currently restored two-page dashboard is the rollback point until task 51
  creates the modular foundation.
- Git recreates all config, templates, assets, and documentation. Only secret
  files require recovery through the existing secret/recovery-pack mechanism.
- Revert one approved phase at a time, recreate only Glance where possible, and
  never delete runtime data or secrets.
