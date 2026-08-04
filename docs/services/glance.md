# Glance

Glance is a lightweight dashboard for bookmarks and small status widgets. In
this deployment it starts with a deliberately quiet config: search plus links to
existing domum services, with no Docker socket and no feed/API polling.

## Enable the Service

Glance is disabled by default. Enable it with `ENABLE_GLANCE`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://glance.${DOMUM_DOMAIN}` through Traefik.

## Configuration

The tracked config lives at:

```text
compose/monitoring/glance/glance.yaml
```

Keep secrets out of this file. If a future widget needs a token, store the token
under `/etc/domum-core/secrets` and pass it through a file-backed environment
variable instead of committing it.

## Data and Backups

Glance has no runtime data in this deployment. Its dashboard config is tracked in
git, so recovery is a rebuild from git followed by `sudo domum-core apply`.

## Updates

Glance participates in the normal container update workflow with
`GLANCE_AUTO_UPDATE` and `GLANCE_UPDATE_DELAY_DAYS`.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
