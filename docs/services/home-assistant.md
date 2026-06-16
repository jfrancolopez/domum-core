# Home Assistant backup & restore

This deployment runs the **container** image
(`ghcr.io/home-assistant/home-assistant:stable`, container `homeassistant`),
config bind-mounted at `compose/automation/home-assistant/`.

HA history (recorder) lives in **MariaDB**, not the config dir — so the HA
backup captures both.

## Backup (never restarts HA)

```bash
sudo domum-core homeassistant backup            # config tar + MariaDB dump
sudo domum-core homeassistant backup --dry-run
```

What it does:

1. Tars the config dir to
   `/var/lib/domum-core/service-backups/homeassistant/ha-YYYYMMDD-HHMMSS.tar.gz`,
   excluding `*.db-wal` / `*.db-shm`, `tts/`, `deps/`, `.cloud`.
2. Dumps **all MariaDB databases** (the recorder DB included) via `mariadb-dump`
   inside the `mariadb` container, to
   `/var/lib/domum-core/service-backups/mariadb/mariadb-all-*.sql.gz`. **This
   doubles as the MariaDB backup.**

It **never** stops or restarts Home Assistant. Both artifacts are swept into
restic via the staging path. Retention: `HA_KEEP` / `MARIADB_KEEP` (default 7).

> HA's own built-in `.tar` backup (Supervisor) is not available in the bare
> container install, so we do not depend on it.

## Restore (manual)

```bash
sudo domum-core homeassistant restore-plan
```

The plan stops HA + MariaDB, restores the config dir non-destructively (moving
the current one aside), reloads the MariaDB dump, then starts HA. Verify at
`https://ha.<domain>` or `:8123`.

## Schedule

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-backups.timer
```
