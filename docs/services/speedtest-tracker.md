# Speedtest Tracker

Speedtest Tracker runs scheduled Ookla internet speed tests against your WAN
and stores the download, upload, ping, and jitter history so you can see
whether the connection is degrading over time.

Project: <https://github.com/alexjustesen/speedtest-tracker> ·
Docs: <https://docs.speedtest-tracker.dev/>

## Enable the Service

Speedtest Tracker is disabled by default. It requires a local `APP_KEY` first:

```bash
sudo install -d -m 0750 -o 1000 -g 1000 \
  /opt/domum-core/compose/monitoring/speedtest-tracker/data
APP_KEY="base64:$(openssl rand -base64 32 2>/dev/null)"
sudo install -d -m 0700 /etc/domum-core/secrets
sudo sh -c "umask 077; cat > /etc/domum-core/secrets/speedtest-tracker.env <<EOF
APP_KEY=$APP_KEY
APP_NAME=Domum Speedtest
DB_CONNECTION=sqlite
DISPLAY_TIMEZONE=America/New_York
SPEEDTEST_SCHEDULE=
SPEEDTEST_SERVERS=
PRUNE_RESULTS_OLDER_THAN=0
EOF"
sudo chmod 0600 /etc/domum-core/secrets/speedtest-tracker.env
sudo domum-core configure
sudo domum-core apply
```

The `APP_KEY` is generated once and must stay stable — regenerating it makes
stored encrypted values unreadable. It lives only in
`/etc/domum-core/secrets/speedtest-tracker.env`, which is bundled into the
encrypted recovery pack.

The compose fragment loads the env file via
`env_file: ${DOMUM_SPEEDTEST_ENV_FILE:-/etc/domum-core/secrets/speedtest-tracker.env}`,
so `apply` fails loudly if the file is missing — never start without `APP_KEY`.
CI validates the fragment against `config/speedtest-tracker.env.example` (the
compose-validate workflow copies it to `.ci/speedtest-tracker.env` and sets
`DOMUM_SPEEDTEST_ENV_FILE`).

## Access

- Public (portal) URL: <https://speedtest.ladomum.com> — served by Traefik on
  `domum-proxy` (router `speedtest`, websecure + `cf` certresolver,
  `securityHeaders@file`). Requires the `speedtest.ladomum.com` DNS record to
  point at the Pi (`10.0.10.2`), the same pattern as the other `*.ladomum.com`
  services.
- Internal URL: `http://speedtest-tracker` (on `domum-data` and
  `domum-proxy`), reachable from other containers.
- Health endpoint: `http://speedtest-tracker/api/healthcheck` → `200` + JSON.

## First Login

The app seeds a default administrator account:

- Email: `admin@example.com`
- Password: `password`

Log in once via the portal URL (or from inside the Docker network) and change
the password and email immediately in the account settings. Keep the new
credentials in Vaultwarden.

If the stored admin password is unknown, reset it with the app's own command:

```bash
docker exec -it speedtest-tracker \
  sh -lc 'cd /app/www && php artisan app:user-reset-password'
```

## Data and Backups

SQLite state and configuration live at:

```text
compose/monitoring/speedtest-tracker/data
```

That directory holds `database.sqlite` (test history and settings), the
generated `/config/.env`, logs, and cache. Everything needed to restore the
service is under this one directory.

`domum-core backups run` includes Speedtest Tracker when
`BACKUP_SPEEDTEST_TRACKER=1`; the service backup briefly pauses the container
while tarring the directory so the SQLite file is consistent.

## Container

| Item | Value |
|---|---|
| Image | `lscr.io/linuxserver/speedtest-tracker:latest` |
| Compose file | `compose/monitoring/speedtest-tracker.yml` |
| Portal URL | `https://speedtest.ladumom.com` (via Traefik, `domum-proxy`) |
| Internal URL | `http://speedtest-tracker` (on `domum-data` and `domum-proxy`) |
| Health endpoint | `http://speedtest-tracker/api/healthcheck` → `200` + JSON |
| Database | SQLite (`database.sqlite` under `/config`) |
| Data directory | `/opt/domum-core/compose/monitoring/speedtest-tracker/data` |
| Timezone | `America/New_York` (host + `TZ` + `DISPLAY_TIMEZONE`) |
| UID/GID | `PUID=1000` / `PGID=1000` (operator `jfranco`) |

Environment variables are split between the compose fragment and
`/etc/domum-core/secrets/speedtest-tracker.env`:

- Compose fragment (non-secret, interpolated at deploy time): `PUID`, `PGID`,
  `TZ`, and `APP_URL=https://speedtest.${DOMUM_DOMAIN}`.
- `/etc/domum-core/secrets/speedtest-tracker.env` (secret and app config, loaded via
  `DOMUM_SPEEDTEST_ENV_FILE`): `APP_KEY`, `APP_NAME`, `DB_CONNECTION`,
  `DISPLAY_TIMEZONE`, `SPEEDTEST_SCHEDULE`, `SPEEDTEST_SERVERS`,
  `PRUNE_RESULTS_OLDER_THAN`.

Only variable names and safe examples are committed in
`config/speedtest-tracker.env.example`. `APP_KEY` never appears in compose, git,
or logs. The separate Homepage widget API token lives in
`/etc/domum-core/secrets/homepage.env` as `HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY`.

## Schedule

Scheduled tests are controlled by `SPEEDTEST_SCHEDULE` in
`/etc/domum-core/secrets/speedtest-tracker.env`, in cron format. It is intentionally left empty
until a manual test is validated. The intended conservative schedule:

```text
30 */6 * * *      # 00:30, 06:30, 12:30, 18:30
```

This avoids the existing 02:30 backup run, 05:15 update check, 05:30 security
patch, and 07:30 checkup timers. After changing the schedule, restart only this
container:

```bash
docker restart speedtest-tracker
```

A scheduled test saturates the WAN link for roughly 30–60 seconds four times a
day. Avoid tightening this schedule without checking
`/etc/systemd/system/domum-core-*.timer` and `crontab -l` for overlaps.

## Run a Test Manually

1. Get an API token with the **Run Speedtest** ability from the web UI
   (`/admin/api-tokens`).
2. Trigger one test (do not run repeated diagnostics; each test saturates the WAN):

```bash
docker exec speedtest-tracker \
  sh -lc 'curl -s -X POST -H "Accept: application/json" \
    -H "Authorization: Bearer TOKEN" \
    http://127.0.0.1/api/v1/speedtests/run'
```

3. Watch it complete in the dashboard or via:

```bash
curl -fsS http://speedtest-tracker/api/healthcheck
```

The first test uses automatic server selection. Record the selected server,
download, upload, and ping; the result must be plausible for your plan before
enabling the schedule.

## View History

Open the web UI and use the Dashboard and Results pages. History is stored
indefinitely (`PRUNE_RESULTS_OLDER_THAN=0`); raise that value only if you want
automatic pruning.

## Pause Scheduled Tests

Set the schedule to empty and restart the container:

```bash
sudo sh -c 'sed -i "s/^SPEEDTEST_SCHEDULE=.*/SPEEDTEST_SCHEDULE=/" /etc/domum-core/secrets/speedtest-tracker.env'
docker restart speedtest-tracker
```

## Upgrade

Speedtest Tracker follows the standard container update workflow with
`SPEEDTEST_TRACKER_AUTO_UPDATE` and `SPEEDTEST_TRACKER_UPDATE_DELAY_DAYS`. It
defaults to manual updates because it is stateful monitoring infrastructure
holding long-term history. To upgrade deliberately:

```bash
sudo docker compose -f compose/base.yml -f compose/monitoring/speedtest-tracker.yml pull speedtest-tracker
sudo docker compose -f compose/base.yml -f compose/monitoring/speedtest-tracker.yml up -d speedtest-tracker
```

## Backup and Restore

Backups are handled by `domum-core backups run` (see above). To restore:

1. Recreate the data directory and set ownership:

```bash
sudo install -d -m 0750 -o 1000 -g 1000 \
  /opt/domum-core/compose/monitoring/speedtest-tracker/data
```

2. Restore `compose/monitoring/speedtest-tracker/data` from the restic snapshot
   into that directory.
3. Restore `/etc/domum-core/secrets/speedtest-tracker.env` from the encrypted
   recovery pack. If no recovery pack is available, regenerate it with the
   **original** `APP_KEY` from Vaultwarden; a different key makes stored
   encrypted values unreadable.
4. Start the service:

```bash
sudo domum-core apply
```

## Logs and Troubleshooting

```bash
sudo docker logs speedtest-tracker
```

If the container stays unhealthy:

- Confirm `/etc/domum-core/secrets/speedtest-tracker.env` exists with a valid `APP_KEY`
  (`curl -fsS http://127.0.0.1/api/healthcheck` inside the container).
- Confirm the data directory is owned by UID 1000 so the app can write the
  SQLite file.
- Check `/config/log/laravel.log` inside the container.

### DNS

The `speedtest.ladumom.com` record lives in the same DNS as the other
`*.ladumom.com` services (Cloudflare records pointing at the Pi's LAN IP
`10.0.10.2`, resolved locally through the router at `10.0.10.1`). Verify:

```bash
getent ahostsv4 speedtest.ladumom.com    # expect 10.0.10.2
```

If it fails to resolve, the route and the `cf` certificate cannot work; check
the record and wait for the local resolver's negative cache to expire.

### TLS

- Certificates are issued by Traefik via the Cloudflare (`cf`) DNS-01 resolver.
  `docker logs traefik` shows issuance progress and errors.
- `curl -fsSI https://speedtest.ladumom.com/` must return a valid cert for
  `speedtest.ladumom.com` with no redirect loop.

### API

- `curl -fsS http://speedtest-tracker/api/healthcheck` must return `200`.
- A 403 on `/api/...` means the API token lacks the required ability (e.g.
  `results:read` to view results, `speedtests:run` to trigger a test).

## Resource and Bandwidth Impact

Idle usage is minimal (a Laravel + nginx + php-fpm stack, a few hundred MB RAM
peaked during a test). During a test the Pi's CPU and temperature rise modestly
and the WAN link is saturated for the test duration. No resource limits are
set: a CPU quota would distort test results, and there is no cap on networking.

## Security Considerations

- No published host port; the container is reachable only through the Traefik
  portal route on `domum-proxy` (`securityHeaders@file`) and the private Docker
  networks. It follows the same `*.ladumom.com` access model as the other
  portal services.
- The app has its own login; change the default `admin@example.com` / `password`
  account after first login.
- `APP_KEY` and the admin credentials are the two things a backup restore
  needs; keep both out of git and in Vaultwarden.

## Homepage Link

The Homepage portal shows a **Speedtest** card under *Network* that opens
`https://speedtest.ladumom.com`, health-checks the internal service URL
(`siteMonitor: http://speedtest-tracker`), and displays latest download,
upload, and ping through the native Speedtest Tracker widget.

The widget uses `http://speedtest-tracker/api/v1/results/latest` from inside
Homepage. Create a token with only the `results:read` ability and set it in the
ignored live file:

```text
/etc/domum-core/secrets/homepage.env
```

```env
HOMEPAGE_VAR_SPEEDTEST_TRACKER_KEY=<read-only token>
```

The card config lives in `compose/monitoring/homepage/services.yaml` and must
reference only the environment variable, never the token value.
