# Task 23 — Automated restore verification (prove backups restore, monthly)

## Objective
"Backups are periodically tested" becomes a timer, not an intention.
`restic check` (already scheduled weekly) verifies repository *integrity*;
nothing verifies that the data inside actually restores into working
app state. The 2026 incident showed recovery paths rot silently.

## Background / current behavior
- `domum-core-backup --check` runs weekly (`domum-core-backup-verify.timer`)
  → catches repo corruption, not content problems.
- No command restores anything automatically; nobody notices if (say) the
  Actual data dir has been excluded by a bad `BACKUP_PATHS` edit, or a tar
  staging step has been failing while restic happily backs up stale archives.

## Desired behavior
A monthly timer runs `domum-core backups verify-restore`:
1. Pick the newest snapshot from one enabled target (rotate: local one month,
   hetzner the next — a tiny state file remembers whose turn it is, so the
   offsite path gets exercised too).
2. `restic restore <snap> --include <critical paths> --target
   $STATE_ROOT/restore-verify/<ts>/` — restore ONLY the small critical set:
   - Actual Budget data dir (expect `*.sqlite` / account dirs present, >0 bytes)
   - HA config dir (expect `configuration.yaml` parseable by `grep`,
     `.storage/core.config_entries` present)
   - newest `mariadb-all-*.sql.gz` (expect `gzip -t` pass + contains
     `CREATE TABLE` for `states` — one `zgrep`)
   - `zigbee2mqtt` dir (expect `configuration.yaml` + `coordinator_backup.json`
     if present in live data)
3. Run cheap validity assertions per item (file exists, size > threshold,
   `gzip -t`, `sqlite3 "PRAGMA integrity_check"` if sqlite3 is installed —
   add to doctor's binary list, optional).
   **Round-2 addition:** when the snapshot contains `BACKUP-MANIFEST.json`
   (task 33), also verify each restored staging artifact's SHA-256 against
   the manifest — an integrity check independent of restic's own trees.
   Missing manifest (older snapshots) = informational skip, never a failure.
4. Write result to `$STATE_ROOT/backups/last-restore-verify` (ok/fail + ts +
   target + snapshot); clean the restore dir.
5. `checkup` gains: warning if last verify failed or is older than ~40 days.
   The weekly report (task 25) surfaces the same line.

The first-ever run should be executed manually and treated as the acceptance
test of the whole backup/restore chain (and of task 22's plumbing).

## Level 2 — the annual fire drill (manual, documented, deliberately not automated)
Round-2 feedback asked how far restore validation should go. Evaluated tiers:

| Tier | What it proves | Verdict |
|---|---|---|
| `restic check` (weekly, exists) | repo integrity | keep |
| artifact validation at creation (exists) | staging tars readable | keep |
| monthly partial restore + structural checks + manifest checksums (this task) | bytes restore, look sane, match recorded hashes | **build — automated** |
| full stack boot from backup on scratch hardware/VM | the entire DR chain incl. wizard, docs, and human | **document as an annual manual fire drill** |
| continuously automated full-restore environment | same, continuously | rejected — second-Pi/VM farm territory; enterprise reflex, not homelab |

The fire drill is a runbook section (add to `docs/backups/disaster-recovery.md`
or a short `docs/backups/fire-drill.md`): once a year (calendar reminder),
take a spare microSD/USB SSD or a VM on another machine, run the real
recovery flow (fresh Debian → install.sh → `domum-core restore` from
Hetzner) with radios left unplugged and Traefik/DNS pointed nowhere, verify
HA UI loads with your dashboards and Actual opens a budget, time the whole
thing, and record date + duration + gotchas in the runbook itself. The first
drill doubles as the acceptance test for tasks 22/26/34. Effort: one evening
a year; it is the only tier that tests the *documentation and the human*,
which is what actually failed margin in the 2026 incident.

## Sizing guard
Restore-verify must stay small: use `--include` filters so it never pulls the
full snapshot (Hetzner egress + NVMe wear). Target: < 500 MB per run. Skip
gracefully (warning, not error) if disk free < 2 GB.

## Implementation plan
1. New function in `bin/domum-core-backup` (or `bin/domum-core`, wherever the
   catalog is visible — prefer `domum-core` so the critical-path list can be
   derived from `backup_src_dir_for()` for HA/actual/z2m instead of a second
   hardcoded list): `verify_restore()`.
2. Wire as `domum-core backups verify-restore` in `backups_cmd`.
3. New unit pair `systemd/domum-core-restore-verify.{service,timer}` —
   monthly (`OnCalendar=*-*-01 04:45:00`, `Persistent=true`), installed by
   the existing `schedule install-maintenance` glob (it already copies
   `domum-core-*.service/timer` — the naming just has to match).
4. checkup addition (~6 lines) reading the state file.
5. Document in `docs/backups/overview.md` (short section: what it proves,
   what it does not — it does not prove app-level semantic correctness, only
   that the bytes restore and look structurally sane).

## Affected files
- `bin/domum-core` (verify logic + checkup lines)
- `systemd/domum-core-restore-verify.service`, `.timer`
- `docs/backups/overview.md`, `docs/operations/maintenance-timers.md`

## Testing plan
- Run manually on the host against the local target; inspect the state file
  and the restored staging tree; confirm cleanup.
- Break it deliberately once (point `--include` at a bogus path) → run must
  fail, checkup must show the warning. Restore the real config.
- `systemd-analyze verify` on the new units; enable the timer.

## Rollback strategy
Disable the timer; the command is read-only against the repos and writes only
under `$STATE_ROOT/restore-verify` + one state file.

## Dependencies
Task 21 (verify the *final* source-set layout, not the current one).
Complements task 22 (shares restic plumbing; whichever lands first, reuse).

## Risks
Low. Worst case is wasted bandwidth on the Hetzner turn — bounded by the
`--include` set.

## Estimated complexity
Medium (~12k tokens).

## Suggested order
Immediately after task 21; before expanding to more destinations (task 24) so
every new destination is born verified.
