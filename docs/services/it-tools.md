# IT-Tools

IT-Tools is a browser-based collection of small utilities for operators and
developers: encoders, formatters, token tools, network calculators, and similar
helpers.

## Enable the Service

IT-Tools is disabled by default. Enable it with `ENABLE_IT_TOOLS`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://tools.${DOMUM_DOMAIN}` through Traefik.

## Data and Backups

IT-Tools is stateless in this deployment. It does not have a persistent data
directory and does not need a `BACKUP_*` flag.

Recovery is only a rebuild from git followed by `sudo domum-core apply`.

## Updates

IT-Tools participates in the normal container update workflow with
`IT_TOOLS_AUTO_UPDATE` and `IT_TOOLS_UPDATE_DELAY_DAYS`.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
