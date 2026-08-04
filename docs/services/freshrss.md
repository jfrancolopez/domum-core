# FreshRSS

FreshRSS is a self-hosted RSS reader. This deployment uses the official stable
image, built-in SQLite, bind-mounted data, and the image's built-in cron to
refresh feeds twice per hour.

## Enable the Service

FreshRSS is disabled by default:

```bash
sudo install -d -m 0750 /opt/domum-core/compose/productivity/freshrss
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://rss.${DOMUM_DOMAIN}` through Traefik. Add a
matching DNS CNAME before using it from the LAN.

## First Login

Open `https://rss.${DOMUM_DOMAIN}` and complete the FreshRSS installer. Use the
built-in SQLite database unless there is a concrete reason to add a separate
database service later. Keep the admin credentials in Vaultwarden.

## Data and Backups

FreshRSS state lives under:

```text
compose/productivity/freshrss
```

`domum-core backups run` includes FreshRSS when `BACKUP_FRESHRSS=1`; the service
backup briefly pauses the container while tarring the directory so SQLite files
are consistent.

## Updates

FreshRSS participates in the normal container update workflow with
`FRESHRSS_AUTO_UPDATE` and `FRESHRSS_UPDATE_DELAY_DAYS`. It defaults to manual
updates because it is stateful and stores user subscriptions and read state.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `rss.${DOMUM_DOMAIN}`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs freshrss` or Dozzle.
