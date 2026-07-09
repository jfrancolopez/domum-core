# Task 24 — Multi-destination backups: Hetzner + Buffalo NAS + Unraid NAS + USB

## Objective
Reach the intended 4-destination posture (Hetzner offsite, Buffalo NAS,
Unraid NAS, manual USB) with the least machinery — and challenge whether all
four belong on the Pi's nightly critical path.

## Background / current behavior
The restic engine is already multi-target: `BACKUP_TARGETS` is a free-form
list and `BACKUP_TARGET_<NAME>_*` keys define each repo (local + hetzner
slots are pre-wired, both currently shipped disabled; the live state on the
Pi must be confirmed during implementation). Task 21 gives the engine
per-target failure isolation — a prerequisite for adding LAN targets that
will occasionally be down.

## Design decision to make first (challenge the assumption)
Four independent nightly restic pushes from the Pi means: 4× backup window,
4 repos to prune/check, 4 credentials, and a Pi that is the single writer to
everything. Two leaner shapes to consider:

**Option A (recommended): 2 nightly targets + 1 replica + on-demand USB**
- Pi pushes nightly to **hetzner** (offsite, authoritative) and **one** LAN
  NAS (fast restore) — pick whichever NAS is more reliable/always-on.
- The second NAS gets its copy via a **NAS-side sync job** (rsync/rclone of
  the first NAS's restic repo directory, or Unraid's own sync tooling). The
  Pi doesn't know it exists; restic repos are just directories and remain
  valid when copied atomically at rest (schedule the sync away from the
  02:30 backup window to avoid copying mid-write; or use `restic copy`
  from the NAS if restic is installable there).
- USB is on-demand (below), not scheduled.
- Trade-off: the second NAS copy lags by up to a day+sync interval, and a
  corrupted primary-NAS repo would replicate; the hetzner repo is the
  independent safety net. Accepted: three independent-enough copies + USB.

**Option B: all three as first-class restic targets on the Pi**
- Simpler mental model ("the Pi owns all backups"), everything visible in
  `backups snapshots`; cost is the 4× fan-out above. Choose B only if the
  NAS boxes can't run a sync job comfortably.

Decide A vs B explicitly at implementation time and record the decision in
`docs/backups/overview.md`. The rest of this task is written for A; B only
changes "add one target" to "add two".

## Implementation plan
1. **Buffalo (or Unraid) as restic target:**
   - Mount decision: prefer an **SFTP** repo (`sftp:user@buffalo-nas:...`)
     over an NFS/SMB mount — no fstab dependency, no hung-mount risk at
     boot, mirrors the hetzner pattern exactly (key file + known_hosts).
     If the NAS can't do SFTP sanely, use a systemd automount + `local`-style
     path target and note the trade-off.
   - Add `BACKUP_TARGET_BUFFALO_*` block to
     `config/domum-backup.conf.example` (copy the hetzner block; port 22).
   - `BACKUP_TARGETS="local hetzner buffalo"` — rename the confusing `local`
     slot? No — keep names, just document that `local` may stay disabled.
   - `sudo domum-core backups init buffalo`; run; verify.
2. **Second NAS replica (option A):** document the NAS-side job in
   `docs/backups/overview.md` (exact rsync command, schedule guidance
   "not 02:00–04:00", and the restore note: a replicated repo restores with
   the same restic password). Nothing to code on the Pi.
3. **USB export/import:**
   - New command: `domum-core backups usb <mount-point>` — validates the
     path is a mounted filesystem (not `/`), then runs a restic backup to a
     repo at `<mount-point>/domum-core-restic` using the LOCAL password file
     (one fewer secret to lose; document that the USB repo shares the local
     restic password), init-on-first-use, then prints
     `restic snapshots` + a reminder to unmount.
   - Restore path: the USB repo is a normal target — `domum-core restore`
     (task 22) can point at it by defining a `usb` target in the conf with
     the mount path, or via an explicit repo flag. Keep it dumb: no udev
     auto-trigger, no auto-mount. Plug, run one command, unplug.
4. **checkup/report integration:** with task 21's per-target status files,
   checkup naturally reports each target's freshness. Add a `USB backup age`
   line (warning-free — informational only, since it is manual and may be
   months old by design; the weekly report shows the date).
5. Update `docs/backups/overview.md` destination matrix:

   | Destination | How | Cadence | Restore speed | Independent? |
   |---|---|---|---|---|
   | Hetzner BX11 | restic sftp | nightly | slow (WAN) | yes |
   | Buffalo NAS | restic sftp | nightly | fast (LAN) | yes |
   | Unraid NAS | NAS-side repo sync | daily | fast (LAN) | replica |
   | USB disk | `backups usb` | manual | fastest | yes (offline) |

## Affected files
- `config/domum-backup.conf.example`
- `bin/domum-core` (`backups_cmd` usb subcommand), `bin/domum-core-backup`
  (nothing if task 21 landed; usb reuses `restic_for_target` with an
  ephemeral target or a small dedicated function)
- `docs/backups/overview.md`, `docs/backups/hetzner.md` (cross-link)

## Testing plan
- `backups run` with NAS unplugged → hetzner still completes (task 21).
- USB: run against a scratch USB stick; snapshots list; restore one file.
- Restore verify (task 23) rotation includes the new target.

## Rollback strategy
Targets are config: set `_ENABLED=0` to drop one instantly. The usb
subcommand is additive.

## Dependencies
Task 21 (isolation) hard; task 23 recommended first.

## Risks
Low-medium: NAS reachability flakiness is absorbed by isolation; repo-copy
replication (option A) must avoid copying during writes — mitigated by
scheduling and/or `restic copy`.

## Estimated complexity
Medium (~12k tokens + NAS-side setup done by the operator).

## Suggested order
After 21 → 26 → 22 → 23.
