# Memos

Memos is a lightweight self-hosted note-taking app for quick Markdown capture.

## Enable the Service

Memos is disabled by default. Enable it with `ENABLE_MEMOS`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://memos.${DOMUM_DOMAIN}` through Traefik.

## First Login

Open the site and create the initial account. Treat the first account as the
owner account and keep the credentials in Vaultwarden.

## Data and Backups

State lives at:

```text
compose/productivity/memos/data
```

Memos uses local SQLite by default. `domum-core backups run` includes Memos when
`BACKUP_MEMOS=1`; the service backup briefly pauses the container while tarring
the directory so SQLite files are consistent.

## Updates

Memos participates in the normal container update workflow with
`MEMOS_AUTO_UPDATE` and `MEMOS_UPDATE_DELAY_DAYS`. It defaults to manual updates
because it is stateful.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs memos` or Dozzle.
