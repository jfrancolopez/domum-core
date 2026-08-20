# Homepage

Homepage is the authoritative Domum Core service directory at
`https://home.${DOMUM_DOMAIN}`. `https://homepage.${DOMUM_DOMAIN}` remains a
direct route for recovery and bookmarks.

## Enable the Service

Homepage is disabled by default. Enable it with `ENABLE_HOMEPAGE`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The portal uses four operator tabs:

- `SYSTEM` for the Raspberry Pi 5, core status, network, calendar, servers, and
  home automation status.
- `APPS` for infrastructure, productivity apps, and security tools.
- `MEDIA` for Plex/Jellyfin/Immich and the external media hosts.
- `FEEDS` for the embedded Glance daily overview and reference bookmarks.

Cards use internal HTTP site monitors where possible; the browser-facing link
always uses HTTPS.

## Configuration

Tracked config lives under:

```text
compose/monitoring/homepage/
```

The config uses `.yaml` files so CI does not treat them as Docker Compose
fragments. Keep secrets out of these files. If a widget needs an API key, store
it in `/etc/domum-core/secrets/homepage.env`.

Homepage also loads an optional root-only env file:

```text
/etc/domum-core/secrets/homepage.env
```

Create it from the tracked example when you are ready to enable credentialed
widgets:

```bash
sudo install -d -m 0700 /etc/domum-core/secrets
sudo install -m 0600 config/homepage.env.example /etc/domum-core/secrets/homepage.env
```

The tracked example stays under `config/`; the live file belongs under
`/etc/domum-core/secrets` and is bundled into the encrypted recovery pack.

The dashboard commits only environment-variable references. Never place OAuth
tokens, API keys, usernames, or passwords in `services.yaml`, `widgets.yaml`, or
`settings.yaml`.

## Live Data Sources

| Feature | Data source | Credential | Refresh | Failure behavior |
|---|---|---|---|---|
| Homepage runtime CPU/RAM | Native Homepage `resources` widget through `systeminformation` | None | 5 seconds | Widget shows unavailable/error state |
| Raspberry Pi temperature | Native Homepage `resources` widget reading mounted `/sys` | None | 5 seconds | Widget omits value if unsupported |
| Root NVMe storage | Native Homepage `resources` widget using `/domum-core` mount | None | 30 seconds | Widget shows unavailable/error state |
| Uptime | Native Homepage `resources` widget | None | 30 seconds | Widget shows unavailable/error state |
| Date/time | Browser `Intl.DateTimeFormat` via Homepage widget | None | Browser-rendered | Browser local rendering |
| Google search | Native Homepage search widget | None | On search | Opens Google search target |
| Durham weather | Native Open-Meteo widget | None | 5 minute cache | Widget shows unavailable/error state |
| Beszel fleet overview | Native Beszel service widget at `http://beszel:8090` | `HOMEPAGE_VAR_BESZEL_USERNAME`, `HOMEPAGE_VAR_BESZEL_PASSWORD` | Homepage widget polling | API error if credentials/system IDs fail |
| Beszel Pi host card | Native Beszel widget with verified Pi system ID | Beszel credentials and Pi system ID var | Homepage widget polling | API error if credentials or the Pi system ID fail |
| AdGuard Home | Native AdGuard widget at `http://adguard-home` | `HOMEPAGE_VAR_ADGUARD_USERNAME`, `HOMEPAGE_VAR_ADGUARD_PASSWORD` | Homepage widget polling | API error if credentials fail |
| Google Calendar | Native Calendar widget with iCal integration | `HOMEPAGE_VAR_GOOGLE_CALENDAR_ICAL_URL` | Homepage widget polling | Calendar shell remains, events absent/error |
| ESPHome | Native ESPHome widget at `http://esphome:6052` | None unless ESPHome auth is enabled | Homepage widget polling | API error if auth is required |
| Service reachability | Homepage `siteMonitor` HEAD/GET to internal URLs | None | Homepage polling | Dot/status becomes unavailable |
| Glance iframe | Native iframe widget to `https://glance.${DOMUM_DOMAIN}` | Browser session/cookies only if Glance requires them | Browser-loaded | Browser shows frame failure; direct link remains |
| Traefik counts | Native Traefik widget through `https://traefik.${DOMUM_DOMAIN}/api/overview` | `HOMEPAGE_VAR_TRAEFIK_USERNAME`, `HOMEPAGE_VAR_TRAEFIK_PASSWORD` | Homepage widget polling | API error if basic auth or dashboard route fails |
| Node-RED flow count | Native Custom API widget at `http://nodered:1880/flows` | None in current runtime | 30 seconds | API error if Node-RED auth is later enabled |
| Backups | Not yet authoritative in Homepage | Healthchecks read-only API key needed | N/A | Shows setup-required card only |
| Plex/Jellyfin/Immich | Not currently enabled | Service URLs and API tokens needed | N/A | Shows API-access-required cards only |

Native `resources` CPU and memory values are Homepage runtime/container values,
not a substitute for Beszel host CPU and memory. Use the Beszel cards for host
metrics. Do not relabel those native values as Raspberry Pi host CPU/RAM unless
Homepage is changed to use a verified host metrics source.

## Operations Center TODO

These signals are intentionally not faked. Add them only when the listed data
source is available and verified from inside the Homepage container.

| Signal | Why it is not live yet | Requirement | Expected result |
|---|---|---|---|
| Healthchecks job totals and backup status | `HOMEPAGE_VAR_HEALTHCHECKS_KEY` is not present | Create a Healthchecks read-only API key and set it in `/etc/domum-core/secrets/homepage.env` | Healthchecks card shows `up` and `down`; backup checks can become the source for overdue/failed backups |
| Home Assistant automation/device health | Home Assistant API requires a long-lived token and `HOMEPAGE_VAR_HOMEASSISTANT_KEY` is not present | Create a read-only HA long-lived access token and choose up to four Homepage custom template metrics | Home Assistant card can show unavailable devices, lights/switches on, or template-based warnings |
| UniFi internet/client health | UniFi URL/account/API key variables are not present | Add a local read-only UniFi account or API key to `/etc/domum-core/secrets/homepage.env` | UniFi card can show WAN/LAN/client/AP counts through the native widget |
| Unraid rich host health | Direct Unraid URL/key are not present; per-host Beszel IDs produced widget API errors in testing | Add `HOMEPAGE_VAR_UNRAID_URL` and `HOMEPAGE_VAR_UNRAID_KEY`, or verify the Beszel system IDs | Unraid card can show CPU, memory, array usage, and notifications |
| N100 rich host health | Per-host Beszel ID produced widget API errors in testing | Verify the `domum-core-media` Beszel system ID and credentials | Media host card can show CPU, RAM, disk, and network via Beszel |
| Traefik certificates and HTTP error rates | Native Homepage Traefik widget exposes routers/services/middleware only | Enable Traefik metrics or a tiny read-only exporter for cert expiry/access-log summaries | Dashboard can report soon-expiring certs and 5xx/404 spikes |
| Zigbee/Z-Wave device health | Frontends are reachable, but no Homepage native widget or simple verified JSON health endpoint is configured | Use Home Assistant templates, MQTT exporter, or a tiny read-only endpoint | Cards can show offline devices, low batteries, dead nodes, and interview failures |
| Speedtest trend | Speedtest Tracker widget reads the latest result only | Keep `HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY` populated with a token that has only `results:read` | Network section shows latest download, upload, and ping |

## Background Image

The background is tracked in git at:

```text
compose/monitoring/homepage/assets/domum-background.svg
```

Homepage serves that directory at `/images` on the direct recovery route, and
`settings.yaml` points to:

```yaml
background:
  image: https://homepage.ladomum.com/images/domum-background.svg
  blur: none
  saturate: 100
  brightness: 100
  opacity: 100
```

To replace it, commit a new file at the same path. Use `2560x1440` or wider
16:9 artwork, keep the file under a few megabytes, and prefer dark, low-contrast
images because Homepage adds glass panels and text on top. After the next
`sudo domum-core update`, restart/recreate Homepage with the normal apply flow.

If a browser still shows the old flat background or vertical tabs after a
Homepage restart, bypass the browser cache before debugging further:

- macOS: `Cmd+Shift+R`
- Linux/Windows: `Ctrl+Shift+R`

Homepage v1.13 renders the dashboard background as `#background`, the root app
as `#__next`, tabs as `#tabs #myTab > li > button`, and top resource cards as
`#information-widgets .widget-container` containing `.information-widget-resource`
pills. Keep custom CSS scoped to those rendered structures instead of guessing
generic widget selectors.

The native datetime widget emits one localized text node such as
`August 5, 2026 at 7:05 PM`. `custom.js` rewrites only that widget into separate
live-updating time and date spans so CSS can render time first and date second
without changing service integrations.

Responsive layout is handled in `custom.css` at these breakpoints:

- Wide desktop: `min-width: 1360px`, tested at `1440px`, `1600px`, and
  `1920px`. Branding is left-aligned in the same row as the five system metrics.
- Desktop: default styles below the wide breakpoint, tested at `1200px`.
- Tablet: `max-width: 900px`, tested at `1024px` and `768px` boundaries.
- Mobile: `max-width: 640px`, tested at `430px` and `390px`.
- Small mobile refinements: `max-width: 480px`.

The top header is intentionally modeled as semantic regions added by
`custom.js`: `.domum-branding`, `.domum-primary-metrics`, `.domum-disk-metric`,
`.domum-uptime-metric`, `.domum-metrics-row`, and `.domum-utility-row`. Those
classes let CSS Grid place branding, primary metrics, secondary metrics, and
utility widgets without depending on Homepage's native flex wrapping. At wide
desktop widths, `custom.css` uses a bounded identity column plus a five-column
metrics strip; smaller widths keep the centered identity above the metrics.

The `SYSTEM` tab service groups are also given semantic classes by `custom.js`:
`.domum-group-core-status`, `.domum-group-servers`, `.domum-group-calendar`,
`.domum-group-network`, and `.domum-group-home-automation`. When all five are
present, `#layout-groups.domum-system-layout` becomes a two-column CSS Grid at
`900px` and wider: Core Status spans the full width, Servers and Calendar use
equal `1fr` columns, and Network plus Home Automation return to full-width rows.
Below `900px`, Homepage keeps the native stacked group flow. The Servers group
intentionally includes only Unraid and `domum-core-media`; the Raspberry Pi is
already represented in the header and Core Status.

Unraid and `domum-core-media` link to Beszel but do not currently render native
Beszel metric blocks on the dashboard. A test using the tracked
`HOMEPAGE_VAR_BESZEL_UNRAID_SYSTEM_ID` and `HOMEPAGE_VAR_BESZEL_MEDIA_SYSTEM_ID`
placeholders produced Homepage widget API errors in the current runtime, so the
cards remain clean links until those per-host Beszel widget IDs are verified.

## Google Calendar

Homepage supports Google Calendar through an iCal URL, not OAuth username and
password login. The dashboard uses the private iCal URL in
`HOMEPAGE_VAR_GOOGLE_CALENDAR_ICAL_URL` when it is present in
`/etc/domum-core/secrets/homepage.env`.

1. Open Google Calendar in the browser.
2. Go to `Settings`.
3. Select the calendar under `Settings for my calendars`.
4. Open `Integrate calendar`.
5. Copy `Secret address in iCal format`. Use the secret address, not the public
   address, unless you intentionally made the calendar public.
6. On the Pi, create or edit `/etc/domum-core/secrets/homepage.env` and add:

```bash
HOMEPAGE_VAR_GOOGLE_CALENDAR_ICAL_URL="https://calendar.google.com/calendar/ical/.../basic.ics"
```

7. Run `sudo domum-core apply` or restart Homepage.

The dashboard shows the monthly calendar shell even before the private iCal URL
is enabled. It sits next to the server summary in the `SYSTEM` tab order. The
widget remains configured with `maxEvents: 4`, but Homepage v1.13's native
monthly calendar view does not render a separate upcoming-events list below the
month grid; no custom event renderer is used.

## Metric Widgets

Native Homepage widgets should only be enabled when a real API endpoint and
credential are available. The dashboard CSS and `blockHighlights` settings are
prepared for `good`, `warn`, and `danger` states, but colors must come from
Homepage widget output or explicit highlight rules, not invented status text.

Beszel overview or verified per-host metrics:

```yaml
widget:
  type: beszel
  url: http://beszel:8090
  username: "{{HOMEPAGE_VAR_BESZEL_USERNAME}}"
  password: "{{HOMEPAGE_VAR_BESZEL_PASSWORD}}"
  systemId: "{{HOMEPAGE_VAR_BESZEL_PI_SYSTEM_ID}}"
  version: 2
  fields: ["name", "status", "updated", "cpu", "memory", "disk", "network"]
  highlight:
    status:
      string:
        - level: danger
          when: regex
          value: "(?i)(down|offline|failed)"
        - level: good
          when: regex
          value: "(?i)(up|online|running)"
    cpu:
      numeric:
        - level: danger
          when: gte
          value: 90
        - level: warn
          when: gte
          value: 75
    memory:
      numeric:
        - level: danger
          when: gte
          value: 90
        - level: warn
          when: gte
          value: 80
```

Only enable per-host widgets for system IDs that have been verified from the
Beszel API. The live dashboard keeps Unraid and `domum-core-media` as clean
Beszel links until those IDs are confirmed, avoiding persistent Homepage API
error banners. Beszel currently requires a superuser for the Homepage API
widget.

UniFi network summary:

```yaml
widget:
  type: unifi
  url: "{{HOMEPAGE_VAR_UNIFI_URL}}"
  site: "{{HOMEPAGE_VAR_UNIFI_SITE}}"
  username: "{{HOMEPAGE_VAR_UNIFI_USERNAME}}"
  password: "{{HOMEPAGE_VAR_UNIFI_PASSWORD}}"
  fields: ["wan", "lan_users", "wlan_users", "wlan_devices"]
```

Create a local UniFi account with read-only access. If using an API key instead,
set `key: "{{HOMEPAGE_VAR_UNIFI_KEY}}"` and omit username/password.

AdGuard Home DNS stats:

```yaml
widget:
  type: adguard
  url: http://adguard-home:3000
  username: "{{HOMEPAGE_VAR_ADGUARD_USERNAME}}"
  password: "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}"
  fields: ["queries", "blocked", "filtered", "latency"]
  highlight:
    latency:
      numeric:
        - level: danger
          when: gte
          value: 100
        - level: warn
          when: gte
          value: 50
```

Allowed fields include queries, blocked, filtered, and latency.

Traefik proxy stats are not currently enabled because `http://traefik:8080` is
not reachable from Homepage in this deployment. Enabling the Traefik API or
changing Traefik middleware is outside the Homepage-only scope and requires
operator approval.

If an approved, reachable endpoint exists later:

```yaml
widget:
  type: traefik
  url: http://traefik:8080
  username: "{{HOMEPAGE_VAR_TRAEFIK_USERNAME}}"
  password: "{{HOMEPAGE_VAR_TRAEFIK_PASSWORD}}"
  fields: ["routers", "services", "middleware"]
```

Allowed fields include routers, services, and middleware.

Healthchecks backup/job summary requires a read-only Healthchecks API key:

```yaml
widget:
  type: healthchecks
  url: http://healthchecks:8000
  key: "{{HOMEPAGE_VAR_HEALTHCHECKS_KEY}}"
  fields: ["up", "down"]
  highlight:
    down:
      numeric:
        - level: danger
          when: gt
          value: 0
        - level: good
          when: eq
          value: 0
```

Plex, Jellyfin, and Immich are shown as setup-required until their real service
URLs and tokens are present in `/etc/domum-core/secrets/homepage.env`. Do not
commit token values.

Plex:

```yaml
widget:
  type: plex
  url: "{{HOMEPAGE_VAR_PLEX_URL}}"
  key: "{{HOMEPAGE_VAR_PLEX_TOKEN}}"
  fields: ["streams", "albums", "movies", "tv"]
  highlight:
    streams:
      numeric:
        - level: warn
          when: gte
          value: 3
```

Jellyfin:

```yaml
widget:
  type: jellyfin
  url: "{{HOMEPAGE_VAR_JELLYFIN_URL}}"
  key: "{{HOMEPAGE_VAR_JELLYFIN_KEY}}"
  version: 2
  enableBlocks: true
  enableNowPlaying: true
```

Immich:

```yaml
widget:
  type: immich
  url: "{{HOMEPAGE_VAR_IMMICH_URL}}"
  key: "{{HOMEPAGE_VAR_IMMICH_KEY}}"
  version: 2
  fields: ["users", "photos", "videos", "storage"]
```

Restart Homepage after each widget batch and check logs before adding the next
batch:

```bash
docker restart homepage
docker logs --since 60s homepage
```

## Restore Readiness

All non-secret dashboard state is tracked in git: layout, tabs, cards, CSS,
background assets, and the `homepage.env.example` template. A fresh Raspberry Pi
restore gets those back through the normal repo bootstrap and `sudo domum-core
apply` flow.

The only Homepage-specific values that are not tracked are live API credentials
and private URLs in `/etc/domum-core/secrets/homepage.env`. Keep that file mode
`600`. It is included in the encrypted recovery pack when present. Recreate it
from `config/homepage.env.example` only if you do not have a current recovery
pack, then restart Homepage.

## Security Model

Homepage does not have the Docker socket mounted. That means it cannot show live
Docker container stats, but a web compromise of Homepage also cannot talk to the
Docker API. Detailed host and container monitoring belongs in Beszel.

Glance is framed only by Homepage through the `glanceEmbedHeaders` middleware.
Do not weaken frame protection globally to make other embeds work.

Runtime logs go to Docker stdout only. The tracked config mount is read-only.

## Data and Backups

Homepage has no runtime data in this deployment. Its dashboard config is tracked
in git, so recovery is a rebuild from git followed by `sudo domum-core apply`.

## Updates

Homepage participates in the normal container update workflow with
`HOMEPAGE_AUTO_UPDATE` and `HOMEPAGE_UPDATE_DELAY_DAYS`. It defaults to manual
updates because dashboards are operator-facing.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `homepage.${DOMUM_DOMAIN}`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
