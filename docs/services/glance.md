# Glance

Glance is the complementary daily overview at `https://dash.${DOMUM_DOMAIN}`.
It provides portal links and curated technology feeds, not a second service
directory or a replacement for Beszel's historical metrics.

## Enable the Service

Glance is disabled by default. Enable it with `ENABLE_GLANCE`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://dash.${DOMUM_DOMAIN}` through Traefik.

## Configuration

The tracked config lives at:

```text
compose/monitoring/glance/glance.yaml
compose/monitoring/glance/pages/
```

`glance.yaml` owns the global server, branding, theme, assets path, and page
order. Individual pages live under `pages/` and are included with Glance `v0.8.5`
`$include` syntax. Shared visual assets live under
`compose/monitoring/glance/assets/`; `domum.css` is loaded through Glance's
`custom-css-file` hook and the Domum-Core SVG mark replaces the old `DC` text
logo. Validate the complete include tree with:

```bash
tests/glance-config-validate.sh
```

Keep secrets out of this file. If a future widget needs a token, store the token
under `/etc/domum-core/secrets` and pass it through a file-backed environment
variable instead of committing it.

The optional direct-widget env file is:

```text
/etc/domum-core/secrets/glance.env
```

Use `config/glance.env.example` as the format. It documents currently consumed
variables and reserved names for approved future widgets. Compose explicitly
clears reserved future variables before starting Glance, so a future adapter must
have its own approved secret plumbing; these names are not permission to
implement a widget without capability-matrix and backlog approval.

Create it on the Pi with root-only permissions:

```bash
sudo install -o root -g root -m 0600 config/glance.env.example /etc/domum-core/secrets/glance.env
sudo editor /etc/domum-core/secrets/glance.env
```

The Network page reads `GLANCE_SPEEDTEST_TRACKER_TOKEN` from this file. Create a
Speedtest Tracker API token from the Speedtest Tracker web UI with the narrowest
available read-only/results scope; it should only need `results:read`. Do not
reuse or mount Homepage's env file for Glance.

The same file may contain `GLANCE_ADGUARD_USERNAME` and
`GLANCE_ADGUARD_PASSWORD` for the Network page's native `dns-stats` widget. Use a
Glance-specific AdGuard web account if practical; otherwise this is an
operator-approved AdGuard credential for aggregate stats only. The widget hides
top domains and does not render raw DNS queries, clients, or domain lists.

The same file supplies the UniFi aggregate-health widget:

```text
GLANCE_UNIFI_URL=
GLANCE_UNIFI_API_URL=
GLANCE_UNIFI_API_KEY=
GLANCE_UNIFI_API_HEADER=X-API-Key
GLANCE_UNIFI_API_PATH=
```

Use `GLANCE_UNIFI_URL` for the UCG Fiber gateway/controller URL reachable from
Glance, including `https://`, and `GLANCE_UNIFI_API_KEY` for a dedicated
read-only key used only for monitoring. `GLANCE_UNIFI_API_URL` is the full
selected site's aggregate health endpoint, also including `https://`. It is
usually `GLANCE_UNIFI_URL` plus a path shaped like
`/proxy/network/api/s/<site-internal-reference>/stat/health`; keep the concrete
site reference only in the root-only env file. The Network page renders only
subsystem status and aggregate counts from that response. The widget requires a
certificate trusted by Glance; it does not disable TLS verification or fall back
to cleartext HTTP. If the controller certificate is issued for a different
hostname, use that trusted hostname in `GLANCE_UNIFI_API_URL` or provide an
approved CA trust mechanism before enabling the widget. It must not call
endpoints that return clients, topology, SSIDs, MAC addresses, IP addresses, or
raw device details.

The same example file also reserves variables for popular but not-yet-consumed
sources:

| Variables | Intended source | How to get them | Status |
|---|---|---|---|
| `GLANCE_HEALTHCHECKS_URL`, `GLANCE_HEALTHCHECKS_API_KEY` | Healthchecks v3 `/api/v3/checks/` project summary | Project Settings read-only API key; never request ping UUIDs or bodies | blocked until key and backup source are approved |
| `GLANCE_CALENDAR_ICS_URL`, `GLANCE_CALENDAR_LOOKAHEAD_DAYS`, `GLANCE_CALENDAR_MAX_EVENTS` | Private/shared calendar events | read-only secret iCal/ICS URL from the calendar provider | future Home adapter task |
| `GLANCE_HOMEASSISTANT_URL`, `GLANCE_HOMEASSISTANT_TOKEN`, `GLANCE_PRESENCE_PERSON_*_NAME`, `GLANCE_PRESENCE_PERSON_*_ENTITY` | Named Home presence | Home Assistant long-lived token plus explicit `person.*` entity allowlist | future Home adapter task |
| `GLANCE_TAUTULLI_URL`, `GLANCE_TAUTULLI_API_KEY` | Plex/Tautulli now-playing/history | Tautulli Settings -> Web Interface/API | future Media task |
| `GLANCE_PLEX_URL`, `GLANCE_PLEX_TOKEN` | Direct Plex fallback | Plex token only if Tautulli is rejected | future Media task |
| `GLANCE_STEAM_API_KEY`, `GLANCE_STEAM_ID64`, `GLANCE_STEAM_COUNTRY` | Steam profile/sales | Steam Web API key from `steamcommunity.com/dev/apikey`; numeric SteamID64 | future Games task |
| `GLANCE_TWITCH_CLIENT_ID`, `GLANCE_TWITCH_CLIENT_SECRET` | Twitch creators/categories | Twitch developer app client credentials | future Games/Social task |
| `GLANCE_SPOTIFY_CLIENT_ID`, `GLANCE_SPOTIFY_CLIENT_SECRET`, `GLANCE_SPOTIFY_REFRESH_TOKEN` | Spotify listening insights | Spotify developer app plus approved OAuth scopes | future Music/Learning task |
| `GLANCE_YOUTUBE_CLIENT_ID`, `GLANCE_YOUTUBE_CLIENT_SECRET`, `GLANCE_YOUTUBE_REFRESH_TOKEN`, `GLANCE_YOUTUBE_API_KEY` | YouTube subscriptions/watch insights | Google Cloud OAuth client and YouTube Data API v3 after scope approval | future Music/Learning task |
| `GLANCE_GITHUB_TOKEN` | GitHub rate-limit relief | fine-grained public metadata read-only token | optional only |

Leave these blank until the matching task is implemented. Do not add personal
OAuth tokens, write-capable API keys, admin accounts, watch history, friend lists,
or raw profile data to Glance.

Spotify and personalized YouTube are especially sensitive because they reveal
taste, routine, attention, and sometimes family presence. Any recommendation
widget must be read-only, explain why it recommends an item, and keep generated
recommendations local to Glance. It must not write playlists, subscribe to
channels, like videos, post comments, or call an external LLM with raw history
unless a later task explicitly approves that data flow.

### Future Home Calendar/Presence Adapter

Private Home events and presence should not be parsed directly in Glance YAML.
The selected design is a small internal adapter, disabled until implemented, that
reads only `/etc/domum-core/secrets/glance.env` and returns sanitized JSON to a
future Home `custom-api` widget.

Calendar setup rules:

- Use `GLANCE_CALENDAR_ICS_URL` for a read-only iCal/ICS URL, ideally from a
  dedicated shared/family calendar rather than a broad personal calendar.
- Keep `GLANCE_CALENDAR_LOOKAHEAD_DAYS` small, defaulting to `7`.
- Keep `GLANCE_CALENDAR_MAX_EVENTS` small, defaulting to `6`.
- Render only approved title/time summaries; avoid locations, attendee lists,
  notes, meeting links, and full descriptions unless explicitly approved later.

Presence setup rules:

- Use `GLANCE_HOMEASSISTANT_URL=http://homeassistant:8123` from the Docker
  network unless a future adapter documents a different route.
- Create a Glance-specific Home Assistant long-lived token from the Home
  Assistant user profile and store it only as `GLANCE_HOMEASSISTANT_TOKEN`.
- Allowlist each person explicitly with `GLANCE_PRESENCE_PERSON_N_NAME` and
  `GLANCE_PRESENCE_PERSON_N_ENTITY`.
- Use only curated `person.*` entities. Do not infer people from UniFi clients,
  device trackers, MAC addresses, IP addresses, SSIDs, or raw device names.
- Render `home`, `away`, and `unknown/stale` style summaries only until a future
  task approves richer location zones.

The optional Beszel integration env file is:

```text
/etc/domum-core/secrets/glance-beszel.env
```

Use `config/glance-beszel.env.example` as the format. The file is loaded only by
the optional adapter, if it exists, and should be mode `0600`, owner `root:root`.
The adapter uses the credential and two approved system mappings server-side;
Glance receives only the sanitized summary response.

Do not create separate `glance_beszel_username` or `glance_beszel_password`
files. If those files were created from an earlier draft, remove them after the
combined env file is populated:

```bash
sudo rm -f /etc/domum-core/secrets/glance_beszel_username /etc/domum-core/secrets/glance_beszel_password
```

Glance has no Docker socket or host filesystem mounts. Do not present its
container-local values as Raspberry Pi metrics; use Beszel for those values.

## Private Access Preparation

The Glance router uses the approved Traefik IP allowlist. Keep the validation
gate enabled on hosts that run Glance and provide both:

```bash
GLANCE_PRIVATE_ACCESS=1
DOMUM_GLANCE_LAN_CIDR="your-lan-cidr"
```

Keep the real CIDR only in `config/domum.conf`; it is private topology and must
not be committed. `sudo domum-core configure --validate` rejects blank or
malformed CIDRs when private access is enabled. When enabled, Traefik permits
only that LAN CIDR and Tailscale's CGNAT range. Test LAN, Tailscale, external
denial, and the Homepage embed after every access-policy change.

Docker must keep `userland-proxy=false` in `/etc/docker/daemon.json`; otherwise
Traefik can see Docker's proxy/NAT source instead of the real Tailscale client
and deny valid tailnet traffic. `domum-core init` converges that daemon setting
for rebuilds, but changing it on a live host requires a Docker restart.

## Data and Backups

Glance has no runtime data in this deployment. Its dashboard config is tracked in
git, so recovery is a rebuild from git followed by `sudo domum-core apply`.

## Updates

Glance is pinned by `GLANCE_IMAGE`, currently `glanceapp/glance:v0.8.5`.
`GLANCE_AUTO_UPDATE=0` is the safe default: review upstream release notes,
change the pin deliberately, run `tests/glance-config-validate.sh`, deploy, and
confirm the running footer/version before accepting a bump.

The validation script uses Glance's own `config:validate` command with dummy
non-secret environment values. It proves the active config parses for the pinned
release; it does not contact live APIs or prove widget data is correct.

## Adding Pages and Widgets

Add a page only after its capability-matrix rows are approved. Put the page in
`compose/monitoring/glance/pages/`, then include it from `glance.yaml` with:

```yaml
pages:
  - $include: pages/new-page.yml
```

Do not add placeholder pages or invented widget types. Community examples must
be copied into the repository only after source, request, credential, cache,
privacy, and failure behavior review.

## Current Pages

- Home: daily command-center hero, action tiles for Home/Network/Hosting, native
  search, month calendar, three clocks, Durham weather, compact service heartbeat,
  Durham air quality, public markets pulse, releases, public infrastructure/AI
  feeds, and selected bookmarks.
- The Home AdGuard monitor checks the Traefik-routed `dns` URL instead of the
  direct container port, because AdGuard's internal web port can move after first
  setup while Traefik owns the stable browser route.
- Hosting: native service monitors for core infrastructure and automation
  dependencies, specialist investigation links, and public releases for installed
  hosting components. It intentionally does not show host metrics, backup state,
  Healthchecks details, certificates, or container lists until those sources are
  separately approved.
- Network: branded command-page treatment with Speedtest Tracker's latest result
  rendered as human-readable WAN pulse metrics, aggregate AdGuard DNS stats with
  top domains hidden, aggregate UniFi subsystem health/counts, plus compact
  reachability checks for approved network-adjacent services. It intentionally
  omits WAN IP, gateway topology, raw DNS activity, UniFi client/device details,
  Tailscale device names, and internal addresses.
- Technology: public engineering videos, self-hosting, infrastructure, security,
  AI feeds, stack releases, bounded Domum Core activity, and watch/read bookmarks.
- News: curated RSS sections for top stories, markets, technology/AI, science,
  and security.
- Social: public creator videos, Hacker News/Lobsters, selected forum RSS feeds,
  and direct community links. Reddit RSS is intentionally not rendered while its
  rate-limit behavior is unresolved. It uses no social-account credentials.
- Media: public videos, film/TV RSS, books/culture RSS, and direct discovery or
  streaming links. It uses no watch-history or personal library integrations.
- Games: public Steam Specials and Top Sellers, gaming videos, gaming/PC/indie RSS feeds, and
  store/community links. It uses no Steam profile, wishlist, friends, play-history,
  or Twitch API credentials.

Private Google Calendar events, WAN identity details, device names, media activity, and
Steam data are intentionally absent until their individual widget tasks approve
credentials and failure behavior.

Beszel-managed external hosts are the selected first external Hosting family.
Glance uses the internal adapter's `/summary` endpoint because direct
`custom-api` login chaining is not safe for Beszel `v0.8.5`. The adapter fetches
only the two configured systems, strips topology and identifier fields, and
returns bounded status/capacity summaries with fresh, stale, and degraded states.
The operator has confirmed the production Pi data path; the remaining dashboard
acceptance work is responsive screenshots and measured resource/request cost.

The adapter service is disabled by default through:

```text
ENABLE_GLANCE_BESZEL_ADAPTER=0
```

Enable it only with both `ENABLE_GLANCE=1` and `ENABLE_BESZEL=1`;
`domum-core configure --validate` and `apply` reject the adapter without those
dependencies. It has no Traefik router and is intended only for the Docker
network path between Glance and Beszel. Its implementation is a repo-local static
Go binary built from `compose/monitoring/glance-beszel-adapter/`; no Go toolchain
is required on the Pi outside Docker build. It exposes `/summary` for Glance and
`/healthz` for direct internal checks.

### Beszel Adapter Pi Validation

Run these only on the production Pi after pulling the adapter commit. Do not
print `glance-beszel.env`, tokens, raw system IDs, raw JSON payloads, internal
addresses, container names, or disk identifiers.

1. Confirm the existing secret file exists and is root-only without showing
   values:

   ```bash
   sudo test -s /etc/domum-core/secrets/glance-beszel.env
   sudo stat -c '%U:%G %a %n' /etc/domum-core/secrets/glance-beszel.env
   ```

2. Enable only after Glance and Beszel are enabled:

   ```text
   ENABLE_GLANCE=1
   ENABLE_BESZEL=1
   ENABLE_GLANCE_BESZEL_ADAPTER=1
   ```

3. Validate config and deploy through the normal production path:

   ```bash
   sudo domum-core configure --validate
   sudo domum-core apply
   ```

4. Confirm the adapter is running without printing sensitive payloads:

   ```bash
   sudo docker inspect --format '{{.State.Health.Status}}' glance-beszel-adapter
   sudo docker run --rm --network domum-proxy curlimages/curl:latest \
     -fsS http://glance-beszel-adapter:8080/healthz
   ```

5. Check `/summary` shape from the same Docker network path. Save output to a
   root-only temp file, inspect keys/counts only, then delete it:

   ```bash
   tmp="$(sudo mktemp)"
   sudo docker run --rm --network domum-proxy curlimages/curl:latest \
     -fsS http://glance-beszel-adapter:8080/summary | sudo tee "$tmp" >/dev/null
   sudo python3 - <<'PY' "$tmp"
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
print("status", data.get("status"))
print("cache", data.get("cache"))
print("systems", len(data.get("systems", [])))
for item in data.get("systems", []):
    print("system", item.get("label"), item.get("status"), "stale", item.get("stale"))
PY
   sudo rm -f "$tmp"
   ```

6. Validate failure behavior during a maintenance window by testing invalid
   credentials, a missing configured system ID, Beszel unavailable, malformed or
   empty upstream behavior where practical, and stale cache behavior. Use a
   temporary env file or temporary service override; restore the real
   `/etc/domum-core/secrets/glance-beszel.env` before leaving the host.

7. If success and failure behavior changes, update the adapter tests and
   capability matrix together. Do not expose raw Beszel payloads while
   investigating.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
