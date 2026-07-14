# Task 39 - App-consistent offsite service archives for database-style apps

## Objective

Decide and implement the smallest reliable way to make offsite backups for
database-style file services app-consistent, without reintroducing the full
duplicate `/var/lib/domum-core/service-backups/` source set that previously
caused excessive Hetzner storage growth.

## Background

Task 21 intentionally shrank `BACKUP_PATHS` so restic stores each byte once in
dedup-friendly raw form:

- `/opt/domum-core/compose`
- `/opt/domum-core/config`
- `/var/lib/domum-core/service-backups/mariadb`
- `/var/lib/domum-core/service-backups/volumes`
- `/var/lib/domum-core/service-backups/BACKUP-MANIFEST.json`
- `/var/lib/domum-core/recovery-pack`

That fixed the storage-churn problem, but it means most service `.tar.gz`
archives under `/var/lib/domum-core/service-backups/*` stay local-only. The
offsite snapshot still includes the raw bind-mounted data directories under
`compose/`, so the data is present, but raw copies of live SQLite/CouchDB-style
stores are not as strong as an archive taken while the application is quiesced
or through an application-native backup path.

This became visible while clarifying the Hetzner B11 backup docs: Actual
Budget, Vaultwarden, and Obsidian Sync data are included offsite through
`compose/`, but the docs must not imply their local service archives are also
offsite by default.

## Current behavior

- Actual Budget: data dir is offsite via
  `/opt/domum-core/compose/productivity/actual-budget/data`; local tar staging
  can be quiesced with `ACTUAL_QUIESCE=1`, but that tar is local-only by
  default.
- Vaultwarden: data dir is offsite via
  `/opt/domum-core/compose/security/vaultwarden/data`; local tar staging is
  quiesced in `service_fs_backup`, but that tar is local-only by default.
- Obsidian Sync: CouchDB data and local config are offsite via
  `/opt/domum-core/compose/productivity/obsidian-sync`; local tar staging is
  currently not CouchDB-native and is local-only by default.
- Home Assistant recorder/history is already handled correctly through the
  MariaDB SQL dump, which is included offsite.

## Desired behavior

The operator can answer, with evidence, whether each database-style app has an
offsite copy that is both present and consistent enough to restore after a Pi
loss.

Do not simply add the entire `/var/lib/domum-core/service-backups` directory
back to `BACKUP_PATHS`.

## Implementation plan

1. Measure current Hetzner impact on the production host:
   `sudo domum-core backups run --dry-run` and restic snapshot file lists for
   the current source set.
2. Pick one of these options per service, documenting the decision:
   - Keep raw bind-mount offsite only, if restore verification proves it is
     reliable enough for that service.
   - Include only a selected app-consistent archive directory in restic for
     that service, with a lower retention count if needed.
   - Use an app-native export instead of a tar if the service provides one
     and it is simpler/reliable enough.
3. If selected archives are added, add explicit `BACKUP_PATHS` entries only for
   those directories, not the entire staging tree.
4. Update `BACKUP_EXCLUDES` or retention knobs so Hetzner growth stays bounded.
5. Update `docs/backups/overview.md` and affected service docs with the final
   per-service consistency story.
6. Coordinate with task 23 so `backups verify-restore` validates whichever
   source is authoritative for each service.

## Affected files

- `bin/domum-core-backup` if `BACKUP_PATHS`/excludes change
- `bin/domum-core` if service backup/quiesce behavior changes
- `config/domum-backup.conf.example`
- `docs/backups/overview.md`
- `docs/services/actual-budget.md`
- `docs/services/vaultwarden.md`
- `docs/services/obsidian-sync.md`
- `docs/backups/disaster-recovery.md`

## Testing plan

- Host: run `sudo domum-core backups run --dry-run` and confirm the path list
  contains exactly the selected authoritative sources.
- Host: run one real backup to Hetzner and inspect `sudo domum-core backups
  snapshots` plus `restic ls latest` for the selected paths.
- Restore spot-check each selected app source to `/var/tmp/domum-restore-test`
  and run cheap integrity checks:
  - `gzip -t` for tar/gzip archives.
  - `sqlite3 ... 'PRAGMA integrity_check;'` when sqlite3 is available and the
    service uses SQLite.
  - CouchDB-specific structural checks for Obsidian if an app-native export is
    not chosen.
- Compare Hetzner repo growth after one week against the current baseline.

## Rollback strategy

If storage growth is unacceptable or a selected archive proves unreliable,
remove the added path from `BACKUP_PATHS` in the live overlay or revert the
default. Old restic snapshots remain immutable and restorable.

## Dependencies

- Task 23 should consume the final authoritative sources in restore
  verification.
- No new dependency may be added without a written justification in this task.

## Risks

Medium. Adding gzipped archives to restic can grow Hetzner usage quickly because
compressed rotations deduplicate poorly. Obsidian/CouchDB consistency needs a
service-specific decision; a hot tar may not be enough.

## Decisions and rejected alternatives

- Rejected: add all of `/var/lib/domum-core/service-backups` back to restic.
  That reopens the storage-churn bug task 21 fixed.
- Rejected: rely on docs alone forever. The raw bind-mount model may be fine,
  but task 23 must prove restore behavior on a schedule.
- Preferred default until measured: keep the current source set and add only
  the smallest authoritative per-service artifacts that restore verification
  cannot validate from raw bind mounts.

## Estimated complexity

Medium.

## Suggested order

Do after task 23's first restore-verification implementation or in the same
session if the verification work shows a concrete service is not safely
recoverable from the current raw offsite copy.
