# Actual Budget backup & restore

Actual stores everything in SQLite under
`compose/productivity/actual-budget/data/` (`ACTUAL_DATA_DIR=/data`), container
name `actual-budget`.

## Backup

```bash
sudo domum-core actual backup            # filesystem-level tar
sudo domum-core actual backup --dry-run  # show what would happen
```

`domum-core backups run` protects Actual offsite in two ways:

- the live data directory under
  `/opt/domum-core/compose/productivity/actual-budget/data`;
- the quiesced service archive under
  `/var/lib/domum-core/service-backups/actual`.

It creates the service archive at
`/var/lib/domum-core/service-backups/actual/actual-YYYYMMDD-HHMMSS.tar.gz` and
keeps the last `ACTUAL_KEEP` (default 7). The archive is included in restic and
is the preferred SQLite restore source after a Pi loss.

### Consistency quiesce

SQLite can be mid-write during a hot copy. For a guaranteed-consistent copy,
use a short `docker pause` around the local tar:

```ini
# config/domum-backup.conf
ACTUAL_QUIESCE=1
```

This pauses the container for the duration of the tar only (seconds), then
unpauses. Existing installs can set `ACTUAL_QUIESCE=0` to opt out.

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
