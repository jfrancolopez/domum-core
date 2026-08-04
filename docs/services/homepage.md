# Homepage

Homepage is a service launcher dashboard. This deployment uses static tracked
configuration only and intentionally does not mount the Docker socket.

## Enable the Service

Homepage is disabled by default. Enable it with `ENABLE_HOMEPAGE`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://homepage.${DOMUM_DOMAIN}` through Traefik.
Add a matching DNS CNAME before using it from the LAN.

## Configuration

Tracked config lives under:

```text
compose/monitoring/homepage/
```

The config uses `.yaml` files so CI does not treat them as Docker Compose
fragments. Keep secrets out of these files. If a future widget needs an API key,
store it under `/etc/domum-core/secrets` and pass it with a `HOMEPAGE_FILE_*`
environment variable.

## Security Model

Homepage does not have the Docker socket mounted. That means it cannot show live
container stats, but a web compromise of Homepage also cannot talk to the Docker
API.

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
