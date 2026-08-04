# Karakeep

Karakeep is a bookmark and web-archive service. This deployment uses the
upstream three-container layout: Karakeep web, headless Chrome, and Meilisearch.
It is disabled by default because Chrome and Meilisearch add noticeable CPU and
memory load on a Raspberry Pi.

## Enable the Service

Karakeep requires a local-only environment file before it can start:

```bash
sudo install -d -m 0700 /etc/domum-core/secrets
sudo sh -c 'printf "NEXTAUTH_SECRET=%s\nMEILI_MASTER_KEY=%s\n" \
  "$(openssl rand -base64 36)" \
  "$(openssl rand -base64 36 | tr -dc A-Za-z0-9)" \
  > /etc/domum-core/secrets/karakeep.env'
sudo chmod 0600 /etc/domum-core/secrets/karakeep.env
sudo install -d -m 0750 /opt/domum-core/compose/productivity/karakeep/data
sudo install -d -m 0750 /opt/domum-core/compose/productivity/karakeep/meilisearch
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://karakeep.${DOMUM_DOMAIN}` through Traefik.
Add a matching DNS CNAME before using it from the LAN.

## First Login

Open `https://karakeep.${DOMUM_DOMAIN}` and create the first account. Keep the
credentials in Vaultwarden.

## Data and Backups

Karakeep state lives under:

```text
compose/productivity/karakeep/data
```

`domum-core backups run` includes Karakeep when `BACKUP_KARAKEEP=1`; the service
backup briefly pauses the web container while tarring the primary app data
directory. Meilisearch data under `compose/productivity/karakeep/meilisearch` is
a runtime search index; rebuild it after restore if needed rather than treating a
hot index copy as the source of truth.

The local secrets live outside git at:

```text
/etc/domum-core/secrets/karakeep.env
```

## Updates

Karakeep participates in the normal container update workflow with
`KARAKEEP_AUTO_UPDATE` and `KARAKEEP_UPDATE_DELAY_DAYS`. It defaults to manual
updates because it is a multi-container stateful app.

Meilisearch version upgrades can require explicit migration work. Review
Karakeep and Meilisearch release notes before changing the Meilisearch image.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `karakeep.${DOMUM_DOMAIN}`.
- Confirm `/etc/domum-core/secrets/karakeep.env` exists.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs karakeep` or Dozzle.
