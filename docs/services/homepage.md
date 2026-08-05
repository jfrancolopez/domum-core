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

- `System` for the Raspberry Pi 5, core status, network, calendar, servers, and
  home automation status.
- `Apps` for infrastructure, productivity apps, and security tools.
- `Feeds` for the embedded Glance daily overview and reference bookmarks.
- `Media` for Plex/Jellyfin/Immich and the external media hosts.

Cards use internal HTTP site monitors where possible; the browser-facing link
always uses HTTPS.

## Configuration

Tracked config lives under:

```text
compose/monitoring/homepage/
```

The config uses `.yaml` files so CI does not treat them as Docker Compose
fragments. Keep secrets out of these files. If a future widget needs an API key,
store it under `/etc/domum-core/secrets` and pass it with a `HOMEPAGE_FILE_*`
environment variable.

Homepage also loads an optional local env file:

```text
config/homepage.env
```

Create it from the tracked example when you are ready to enable credentialed
widgets:

```bash
cp config/homepage.env.example config/homepage.env
chmod 600 config/homepage.env
```

`config/*.env` is ignored by git. Do not commit the live file.

The current dashboard intentionally does not commit credentialed service widgets.
Detailed metrics for Gmail Calendar, UniFi, AdGuard Home, Traefik, Plex,
Jellyfin, Immich, Unraid, and Beszel require API credentials or dedicated
read-only endpoints. Add those only with file-backed secrets; never place OAuth
tokens, API keys, usernames, or passwords in `services.yaml`, `widgets.yaml`, or
`settings.yaml`.

## Background Image

The background is tracked in git at:

```text
compose/monitoring/homepage/assets/domum-background.svg
```

Homepage serves that directory at `/images`, and `settings.yaml` points to:

```yaml
background:
  image: /images/domum-background.svg
  blur: sm
  saturate: 50
  brightness: 50
  opacity: 30
```

To replace it, commit a new file at the same path. Use `2560x1440` or wider
16:9 artwork, keep the file under a few megabytes, and prefer dark, low-contrast
images because Homepage adds glass panels and text on top. After the next
`sudo domum-core update`, restart/recreate Homepage with the normal apply flow.

## Google Calendar

Homepage supports Google Calendar through an iCal URL, not OAuth username and
password login.

1. Open Google Calendar in the browser.
2. Go to `Settings`.
3. Select the calendar under `Settings for my calendars`.
4. Open `Integrate calendar`.
5. Copy `Secret address in iCal format`. Use the secret address, not the public
   address, unless you intentionally made the calendar public.
6. On the Pi, create or edit `config/homepage.env` and add:

```bash
HOMEPAGE_VAR_GOOGLE_CALENDAR_ICAL_URL="https://calendar.google.com/calendar/ical/.../basic.ics"
```

7. In `compose/monitoring/homepage/services.yaml`, uncomment the `integrations`
   block under the `Gmail Calendar` widget.
8. Run `sudo domum-core apply` or restart Homepage.

The dashboard currently shows the monthly calendar even before the private iCal
URL is enabled. It is intentionally constrained to half width on desktop and
uses `maxEvents: 4` so meetings stay subtle below the month grid.

## Metric Widgets

Native Homepage widgets can replace the placeholder cards once read-only
credentials exist. The dashboard CSS and `blockHighlights` settings are already
prepared for `good`, `warn`, and `danger` states. Add credentials to
`config/homepage.env`, then add the widget block to the relevant service in
`compose/monitoring/homepage/services.yaml`.

Beszel overview or per-host metrics:

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

Use `HOMEPAGE_VAR_BESZEL_MEDIA_SYSTEM_ID` for `domum-core-media` and
`HOMEPAGE_VAR_BESZEL_UNRAID_SYSTEM_ID` for Unraid. Beszel currently requires a
superuser for the Homepage API widget.

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

Traefik proxy stats:

```yaml
widget:
  type: traefik
  url: http://traefik:8080
  username: "{{HOMEPAGE_VAR_TRAEFIK_USERNAME}}"
  password: "{{HOMEPAGE_VAR_TRAEFIK_PASSWORD}}"
  fields: ["routers", "services", "middleware"]
```

Allowed fields include routers, services, and middleware.

Healthchecks backup/job summary:

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
and private URLs in `config/homepage.env`. If you want credentialed widgets to
come back after bare-metal restore, keep a copy of those values in the same
password manager entry or recovery notes used for other Domum secrets. Recreate
`config/homepage.env` from `config/homepage.env.example` after restore, then
restart Homepage.

## Security Model

Homepage does not have the Docker socket mounted. That means it cannot show live
container stats, but a web compromise of Homepage also cannot talk to the Docker
API. Detailed host and container monitoring belongs in Beszel.

Traefik applies `X-Frame-Options: DENY`. Homepage is intentionally not embedded
in Glance; use the explicit Glance and Beszel links instead.

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
