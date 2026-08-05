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

- `System` for the Raspberry Pi 5, network operations, fleet hosts, and home
  automation status.
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

The current dashboard intentionally does not commit credentialed service widgets.
Detailed metrics for Gmail Calendar, UniFi, AdGuard Home, Traefik, Plex,
Jellyfin, Immich, Unraid, and Beszel require API credentials or dedicated
read-only endpoints. Add those only with file-backed secrets; never place OAuth
tokens, API keys, usernames, or passwords in `services.yaml`, `widgets.yaml`, or
`settings.yaml`.

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
