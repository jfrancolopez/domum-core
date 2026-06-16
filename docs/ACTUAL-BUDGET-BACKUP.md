# Actual Budget backup & restore

Actual stores everything in SQLite under
`compose/productivity/actual-budget/data/` (`ACTUAL_DATA_DIR=/data`), container
name `actual-budget`.

## Backup (default: no downtime)

```bash
sudo domum-core actual backup            # filesystem-level tar
sudo domum-core actual backup --dry-run  # show what would happen
```

Creates `/var/lib/domum-core/service-backups/actual/actual-YYYYMMDD-HHMMSS.tar.gz`
and keeps the last `ACTUAL_KEEP` (default 7). The artifact is swept into restic
via the staging path, so a single `backups run` captures it offsite too.

### Optional consistency quiesce

SQLite can be mid-write during a hot copy. For a guaranteed-consistent copy,
opt into a short `docker pause` around the tar:

```ini
# config/domum-backup.conf
ACTUAL_QUIESCE=1
```

This pauses the container for the duration of the tar only (seconds), then
unpauses. Default is `0` (no downtime).

## Restore (non-destructive)

```bash
sudo domum-core actual restore-plan
```

The plan never overwrites in place: it stops the container, moves the current
`data/` dir aside to `data.bak-<timestamp>`, extracts your chosen archive, and
restarts. If anything is wrong, restore the `.bak` dir and start again.

## Schedule

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-backups.timer
```
