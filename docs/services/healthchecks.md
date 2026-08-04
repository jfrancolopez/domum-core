# Healthchecks

Healthchecks monitors cron jobs and scheduled tasks by receiving HTTP pings.
This deployment starts small: one container, SQLite storage, no SMTP listener,
and no outbound email configured by default.

## Enable the Service

Healthchecks is disabled by default. It requires a local secret first:

```bash
sudo install -d -m 0700 /etc/domum-core/secrets
sudo sh -c 'openssl rand -hex 48 > /etc/domum-core/secrets/healthchecks_secret_key'
sudo chmod 0644 /etc/domum-core/secrets/healthchecks_secret_key
sudo install -d -m 0750 -o 999 -g 999 \
  /opt/domum-core/compose/monitoring/healthchecks/data
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://checks.${DOMUM_DOMAIN}` through Traefik. Add a
matching DNS CNAME before using it from the LAN.

## First Login

Public registration is closed. Create the first user inside the container:

```bash
sudo docker exec -it healthchecks \
  /opt/healthchecks/manage.py createsuperuser
```

Keep the credentials in Vaultwarden.

## Data and Backups

SQLite state lives at:

```text
compose/monitoring/healthchecks/data
```

`domum-core backups run` includes Healthchecks when `BACKUP_HEALTHCHECKS=1`; the
service backup briefly pauses the container while tarring the directory so SQLite
files are consistent.

The Django `SECRET_KEY` lives outside git at:

```text
/etc/domum-core/secrets/healthchecks_secret_key
```

## Updates

Healthchecks participates in the normal container update workflow with
`HEALTHCHECKS_AUTO_UPDATE` and `HEALTHCHECKS_UPDATE_DELAY_DAYS`. It defaults to
manual updates because it is stateful monitoring infrastructure.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `checks.${DOMUM_DOMAIN}`.
- Confirm `/etc/domum-core/secrets/healthchecks_secret_key` exists.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs healthchecks` or Dozzle.
