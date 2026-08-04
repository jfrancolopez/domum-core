# Dozzle

Dozzle is a live Docker log viewer for operators. It is useful when checking a
container during maintenance without opening an SSH session for every log tail.

## Enable the Service

Dozzle is disabled by default. Enable it with `ENABLE_DOZZLE`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://logs.${DOMUM_DOMAIN}` through Traefik.

## Security Model

Dozzle mounts `/var/run/docker.sock` read-only so it can list containers and read
logs. Treat access to Dozzle as operator-level access to the host.

The Traefik route uses the existing `traefik-auth@file` basic-auth middleware and
`securityHeaders@file`. Do not expose this route without authentication.

Dozzle analytics are disabled with `--no-analytics`.

## Data and Backups

This deployment does not configure Dozzle's app-level users or persistent data.
It has no `BACKUP_*` flag. Recovery is a rebuild from git followed by
`sudo domum-core apply`.

## Updates

Dozzle participates in the normal container update workflow with
`DOZZLE_AUTO_UPDATE` and `DOZZLE_UPDATE_DELAY_DAYS`. It defaults to manual updates
because it has Docker socket visibility.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm Traefik dashboard basic-auth credentials are present.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
