# ntfy

ntfy is a self-hosted notification service. This deployment is intended for
operator alerts from domum-core, monitoring jobs, and future integrations.

## Enable the Service

ntfy is disabled by default. Enable it with `ENABLE_NTFY`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://ntfy.${DOMUM_DOMAIN}` through Traefik.

## Security Model

This instance is private by default:

- `NTFY_AUTH_DEFAULT_ACCESS=deny-all`
- login is enabled
- public signups are disabled

Create users and access tokens explicitly after enabling the service. Example:

```bash
sudo docker exec -it ntfy ntfy user add --role=admin <user>
sudo docker exec -it ntfy ntfy token add <user>
```

Do not switch anonymous access to `read-write` unless the route is private to a
trusted network. An open ntfy instance can be abused as a public relay.

## Data and Backups

State lives at:

```text
compose/monitoring/ntfy/data
```

It includes SQLite files for message cache and auth metadata. `domum-core backups
run` includes ntfy when `BACKUP_NTFY=1`; the service backup briefly pauses the
container while tarring the directory so SQLite files are consistent.

## Updates

ntfy participates in the normal container update workflow with
`NTFY_AUTO_UPDATE` and `NTFY_UPDATE_DELAY_DAYS`. It defaults to manual updates
because it is stateful and may become part of alert delivery.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs ntfy` or Dozzle.
