# domum-core audit

Snapshot of the repository's state when the production management layer
(backup / checkup / recovery / updates) was added, plus the bugs that work
fixed.

## Service inventory

12+ services toggled in `config/domum.conf`. Enabled by default: `traefik`,
`home-assistant`, `mariadb`, `go2rtc`, `mqtt`, `zigbee2mqtt`, `zwave-js-ui`,
`nodered`, `esphome`, `music-assistant`, `portainer`, `adguard-home`,
`actual-budget`. Disabled by default: `frigate`, `uptime-kuma`, `jellyfin`,
`tailscale`.

## Compose layout

Fragment-per-service under `compose/<category>/*.yml`, composed by
`compose_files_for_enabled_services()` in `bin/domum-core`. `compose/base.yml`
defines networks (`domum-proxy` / `domum-internal` / `domum-data`) and named
volumes. Compose profiles: `core` / `night` / `media` / `ai`.

Container names (resolved at runtime, never hardcoded in backup logic): see
`container_name:` in each fragment — e.g. `homeassistant`, `actual-budget`,
`mariadb`, `musicassistant`, `zwave-js-ui`.

## Persistent data (two patterns)

**Bind mounts under `/opt/domum-core/compose/...`** — the critical,
hard-to-recreate state:

| Service        | Path |
|----------------|------|
| Home Assistant | `compose/automation/home-assistant/` |
| MariaDB        | `compose/automation/mariadb/data/` |
| MQTT           | `compose/automation/mqtt/{config,data,log}/` |
| Zigbee2MQTT    | `compose/automation/zigbee2mqtt/` |
| Z-Wave JS UI   | `compose/automation/zwave-js-ui/store/` |
| ESPHome        | `compose/automation/esphome/` |
| Music Assistant| `compose/automation/music-assistant/` |
| AdGuard Home   | `compose/networking/adguard/{work,conf}/` |
| Actual Budget  | `compose/productivity/actual-budget/data/` |
| Traefik config | `compose/proxy/traefik/` |

**Named volumes** (easy to miss in backups): `traefik-letsencrypt`,
`uptime-kuma-data`, `portainer-data`, `nodered-data`, `jellyfin-config`,
`jellyfin-cache`. **Node-RED flows live in a named volume** —
`bin/domum-core-backup` exports the configured named volumes to tar staging so
they ride along in restic.

## Secrets / env

Secrets live **outside the repo** at `/etc/domum-core/secrets/`
(`cloudflare_api_token`, `mariadb/mariadb.env`, `traefik_dashboard_users`,
`go2rtc/`, `frigate/`, `tailscale_authkey`). HA `secrets.yaml` and Zigbee2MQTT
`secret.yaml` are bind-mounted from the repo tree. `.gitignore` excludes
`.env`, `secrets/`, `**/data/`, z2m `secret.yaml`.

## Bugs / inconsistencies fixed in this work

- **Secrets path drift** — `install.sh` and `bin/night-profile.sh` referenced
  `$DOMUM_DIR/secrets` (`/opt/domum-core/secrets`), while `bin/domum` and every
  compose file use `/etc/domum-core/secrets`. **Standardized on
  `/etc/domum-core/secrets`** in both files.
- **`update` did `git reset --hard origin/main`** unconditionally, destroying
  local config drift on the Pi. **Softened** to warn and require confirmation
  when local changes are present.

## Gaps this work closes

- **Backup** — none in code before (only an rsync doc). Now: restic multi-target
  wrapper + per-service backups for Actual, HA, and MariaDB.
- **Restore** — no documented path. Now: `restore-plan` subcommands +
  `docs/DISASTER-RECOVERY.md`.
- **Health checks** — none beyond compose. Now: `checkup` / `doctor`.
- **Disaster recovery** — secrets existed only on the Pi. Now: AGE-encrypted
  recovery pack + runbook.
- **Updates** — `image: latest` + `git reset --hard` = uncontrolled. Now: a
  cautious, class-based `updates` command with a backup gate and history.

## What remains the operator's responsibility

Restic repos/passwords must be filled in and enabled; the AGE keypair must be
generated (private key kept offline); timers must be enabled; offsite/Hetzner
and email need credentials. Frigate media and Jellyfin libraries are
intentionally excluded from backups.
