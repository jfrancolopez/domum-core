# Beszel

Beszel is a lightweight server monitoring UI. This first deployment runs the hub
only. The local agent is intentionally not added yet because it needs a token/key
created from the hub UI and requires Docker socket or host metric access.

## Enable the Hub

Beszel is disabled by default. Enable it with `ENABLE_BESZEL`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The hub is exposed as `https://beszel.${DOMUM_DOMAIN}` through Traefik. Add a
matching DNS CNAME before using it from the LAN.

## First Login

Open the hub and create the first admin account. Keep the credentials in
Vaultwarden.

## Agent Follow-Up

Do not add the local agent by hand outside git. After the hub is running, create
the local system/token in the Beszel UI, then add a follow-up compose change for
`beszel-agent` using secrets or local config for the generated token/key.

That follow-up should explicitly review Docker socket exposure and Pi resource
impact.

## Data and Backups

Hub state lives at:

```text
compose/monitoring/beszel/data
```

Beszel uses PocketBase/SQLite-style local state. `domum-core backups run`
includes Beszel when `BACKUP_BESZEL=1`; the service backup briefly pauses the
container while tarring the directory so database files are consistent.

## Updates

Beszel participates in the normal container update workflow with
`BESZEL_AUTO_UPDATE` and `BESZEL_UPDATE_DELAY_DAYS`. It defaults to manual
updates because it is stateful monitoring infrastructure.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `beszel.${DOMUM_DOMAIN}`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs beszel` or Dozzle.
