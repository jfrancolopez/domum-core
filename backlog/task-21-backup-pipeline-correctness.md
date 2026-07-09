# Task 21 — Backup pipeline correctness pass (isolation, source set, consistency)

## Objective
Fix three structural weaknesses in the backup pipeline so that (a) one failing
target cannot cancel the others, (b) the restic source set stops storing the
same data twice, and (c) SQLite-backed services get consistent copies.

## Background
`domum-core backups run` does: service-level tars into
`/var/lib/domum-core/service-backups/` → restic push of `BACKUP_PATHS` to every
enabled target (`bin/domum-core-backup`). Three verified problems:

### Problem A — no per-target failure isolation
`bin/domum-core-backup` runs `set -euo pipefail`, and `do_daily_backup()` calls
`restic_backup_to "$target"` in a loop **without** `||` handling. One failing
target (Hetzner unreachable, NAS unmounted) aborts the whole script:
- targets later in `BACKUP_TARGETS` never run that night;
- `restic forget` (retention) is skipped for targets that DID succeed;
- the heartbeat file is not written, so `checkup` flags staleness — correct
  outcome, wrong reason (the local backup may have succeeded).
With the multi-NAS plan (task 24), a flaky LAN target must never cancel the
offsite backup or vice versa.

### Problem B — the restic source set stores everything twice (or thrice)
`BACKUP_PATHS` (bin/domum-core-backup, ~line 45) includes:
1. every critical bind-mount dir individually (`compose/automation/home-assistant`, …),
2. **plus** the whole `$DOMUM_DIR/compose` tree (which already contains all of #1),
3. **plus** `$STATE_ROOT/service-backups` — the tar.gz staging of the *same*
   data, 7 rotations per service.
Consequences: gzipped tars are opaque to restic dedup, so each of the ~7×11
archives is stored nearly in full, every prune cycle churns them, and the
Hetzner BX11 fills with N copies of identical data. The individual path list
(#1) is pure noise since #2 covers it.
Additionally `compose/automation/mariadb/data` (raw InnoDB files, copied while
mariadbd is running) is in the set — a raw hot copy of InnoDB is **not** a
reliable restore source; the `mariadb-dump` SQL artifact is the authoritative
backup and already exists.

### Problem C — hot SQLite copies without quiesce
- Actual Budget: SQLite, `ACTUAL_QUIESCE=0` by default → tar can capture a
  mid-write DB. The quiesce costs a sub-second `docker pause` at 02:30.
- Vaultwarden: SQLite (`db.sqlite3`), tarred hot by `service_fs_backup` with
  no quiesce option at all. This is the password manager — the one service
  where a corrupt backup is discovered exactly when it matters most.
- (HA is fine: recorder is MariaDB; `.storage/` is JSON files.)

## Desired behavior
- Every enabled target is attempted every run; failures are collected and the
  run exits non-zero listing which target(s) failed; retention + heartbeat run
  per-target for the ones that succeeded.
- Each byte of service data is stored in restic **once**, in restic's own
  dedup-friendly form. Local tar staging remains (fast same-host restores,
  update backup-gate freshness) but does not ride into restic — except the
  MariaDB SQL dumps, which are the only artifacts not reproducible from raw
  files.
- SQLite services are quiesced (paused) for the seconds their tar takes, at
  night, by default.

## Implementation plan
1. **Isolation:** in `do_daily_backup()` / `do_check()` / `do_prune()`, wrap
   per-target work: `restic_backup_to "$t" || { failed+=("$t"); continue; }`.
   Track per-target success; run `restic_forget_for` only for succeeded
   targets. Write the heartbeat if **at least one** target succeeded, and
   write a per-target status file
   (`$STATE_ROOT/backups/last-success-<target>`) so `checkup` (and the weekly
   report, task 25) can say *which* destination is stale. Teach
   `restic_backup_fresh` / checkup's freshness section to read per-target
   files when present (keep the aggregate file for back-compat).
2. **Source set:** change the `BACKUP_PATHS` default to:
   ```
   $DOMUM_DIR/compose  $DOMUM_DIR/config
   $STATE_ROOT/service-backups/mariadb   # SQL dumps only
   $STATE_ROOT/recovery-pack
   ```
   and add `BACKUP_EXCLUDES` entries for `compose/automation/mariadb/data`
   (raw InnoDB — dump is authoritative; document why in a comment) and any
   other regenerables found during implementation. Named-volume exports
   (`service-backups/volumes/*.tar.gz`) must stay included — they are the
   only capture of nodered/uptime-kuma/letsencrypt volumes; keep them by
   adding `$STATE_ROOT/service-backups/volumes` to the path list.
   Verify on the host with `restic backup --dry-run` that the file count
   drops as expected and nothing critical disappears (diff the file list).
3. **Consistency:** default `ACTUAL_QUIESCE=1`; add the same generic
   pause-tar-unpause wrapper to `service_fs_backup` for services flagged
   sqlite (vaultwarden at minimum — a small case list or a new catalog
   column; prefer the case list, it is 3 lines). Document the ~seconds pause
   in `docs/backups/overview.md`.
4. Update `config/domum-backup.conf.example` comments and
   `docs/backups/overview.md` "What gets backed up" section to match.
5. **Do not** add per-service schedules. Daily at 02:30 for everything stays —
   simpler, and RPO 24h was accepted in the DR runbook. If a tighter RPO for
   Actual/HA is ever wanted, the right knob is a second small timer running
   `domum-core actual backup` + `homeassistant backup` (staging only, no
   restic) — note this as a comment, do not build it.

## Affected files
- `bin/domum-core-backup` (isolation, BACKUP_PATHS, excludes)
- `bin/domum-core` (`service_fs_backup` quiesce, checkup freshness reading,
  `ACTUAL_QUIESCE` default)
- `config/domum-backup.conf.example`, `docs/backups/overview.md`

## Testing plan
- Host: `sudo domum-core backups run --dry-run` — review path list.
- Simulate a target failure (temporarily point hetzner repo at a bogus host):
  local target still completes, run exits non-zero naming hetzner, heartbeat
  for local written.
- `sudo domum-core backups run` for real; `snapshots` on both targets;
  restore one file from the new snapshot layout to prove nothing critical
  was excluded (`restic restore --include .../actual-budget/data --target /tmp/x`).
- After a week, compare Hetzner repo size trend (expect it to flatten).

## Rollback strategy
Everything is config-defaulted: restore old `BACKUP_PATHS`/`ACTUAL_QUIESCE`
values in the live overlay to get old behavior without reverting code. Old
snapshots remain restorable regardless (restic snapshots are immutable).

## Dependencies
None hard. Do **before** task 24 (multi-destination) so new targets inherit
the fixed engine, and before task 23 (restore verification) so it verifies
the final layout.

## Risks
Medium: shrinking the source set can drop something needed. Mitigations: the
snapshot diff in testing; old snapshots retain everything for months per
retention policy; keep the change to the *default* so the live overlay can
override instantly.

## Estimated complexity
Medium (~15k tokens).

## Suggested order
First item of the backup/recovery phase.
