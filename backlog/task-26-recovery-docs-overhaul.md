# Task 26 — Recovery documentation overhaul (accuracy + consolidation + storage-replacement runbook)

## Objective
Make every recovery document correct, current, and executable verbatim by a
stressed operator. Fix the outright wrong commands, kill the stale duplicate
doc, and write the missing runbook the NVMe incident proved necessary.

## Verified defects to fix

### A. `docs/backups/disaster-recovery.md`
1. **Wrong restore command (would corrupt the layout):**
   `sudo domum-core-backup --restore latest /opt/domum-core local` —
   restic reproduces absolute paths **under** `--target`, so this creates
   `/opt/domum-core/opt/domum-core/...`. Correct form:
   `--restore latest /tmp/restore` then move/rsync into place, or
   `--target /` (with the caveats). Rewrite this step (or, once task 22
   lands, replace it with `sudo domum-core restore` and keep the manual form
   as an appendix).
2. Wrong repo URL (`solosoyfranco/...` — coordinate with task 02) and wrong
   OS ("Flash Raspberry Pi OS (64-bit)") — production is **Debian 13 Lite**
   on **native NVMe boot**; say that, and link the imaging steps.
3. The USB-radio note says device paths "differ on new hardware" — misleading.
   `/dev/serial/by-id/*` paths are derived from the dongle's USB descriptors
   (vendor/product/serial), so they are **identical on a new Pi with the same
   dongles** and never change with the physical port. They change only when a
   *dongle* is replaced. Correct the note: "paths follow the dongle, not the
   Pi or the port; only edit compose if you replaced the radio itself".
4. Add the install.sh ordering warning (see task 19): install **before**
   restoring anything to /opt/domum-core.

### B. `docs/backups/migrating-between-hosts.md` — delete and redirect
Every path in it is wrong (`/etc/domum/secrets`, `/etc/domum/domum.conf` —
real paths are `/etc/domum-core/secrets` and `/opt/domum-core/config/*`), the
URL is the stale one, the rsync-data step predates restic, and the network
list omits `domum-data`. It is a pre-modernization draft that now actively
misleads. Planned migration and disaster recovery are the same procedure with
different urgency — replace the file with 5 lines pointing at
`disaster-recovery.md` (plus the one genuinely migration-specific note:
you can rsync live data directly host-to-host instead of going through
restic, stopping containers first). Do not maintain two runbooks.

### C. New: `docs/operations/storage-replacement.md` (the missing runbook)
The NVMe migration happened without a written procedure. Capture it while it
is still rememberable — **but frame it under the disposable-OS principle
(round-2 feedback):** rebuild-from-scratch (fresh image + bootstrap +
`domum-core restore`) is the *recovery* path and the one that gets tested;
drive cloning is documented only as a time-saving *convenience for planned
swaps* where the old drive is healthy and in hand. The runbook must open
with that sentence and a decision rule: "old drive healthy and you have an
hour → clone; anything else, or any doubt → rebuild." Never let cloning
become the implicit recovery plan again. Cover both paths:
1. **Planned boot-drive replacement** (SSD→NVMe, small→big NVMe):
   attach new drive via USB adapter → partition + copy
   (`rpi-clone`-style or manual sfdisk + rsync -aHAX with the correct
   exclusions: /proc /sys /dev /run /tmp) → fix `PARTUUID` in
   `/boot/firmware/cmdline.txt` + `/etc/fstab` → EEPROM boot order
   (`rpi-eeprom-config`: NVMe first for the PCIe HAT) → swap, boot, verify
   (`findmnt /`, `docker ps`, `domum-core checkup`).
   Stop containers before the final rsync pass (data consistency):
   `docker stop $(docker ps -q)` → rsync delta → swap.
2. **Failed-boot-drive recovery**: decision tree — drive readable elsewhere?
   → clone per above from a USB adapter on any Linux box; unreadable? → full
   DR runbook (fresh install + `domum-core restore`).
3. **Replacing the Pi itself** (drive healthy): move NVMe + radios to the new
   Pi; what actually needs attention (EEPROM boot order on the new board,
   nothing else — by-id radio paths and everything on disk carry over).
Cross-link from disaster-recovery.md and the docs index.

### D2. Tailscale state — declare the intentional loss
`data/tailscale` is not in `BACKUP_PATHS` (and should not be — node keys are
re-issuable). After a rebuild, Tailscale needs a fresh auth key. Say so in
disaster-recovery.md ("expected: re-authenticate Tailscale; 2 minutes; here
is where the auth key goes") so the omission reads as designed, not as a
hole discovered mid-recovery. Currently `ENABLE_TAILSCALE=0`, but the doc
line costs nothing and remote-access recovery is exactly what a stressed
operator will reach for first.

### D. Small accuracy sweep in the same session
- `docs/backups/overview.md`: reflects task 21's source-set changes (if
  landed); Hetzner repo string shown in two different forms
  (`:domum-core` vs `:/./domum-core-restic`) — standardize on the `/./` form
  everywhere.
- `docs/reference/service-template.md`: stale duplicate of
  `add-new-service.md` (references the pre-catalog `bin/domum` if-chain,
  `${DOMUM_DIR}/data/...` mounts, `certresolver=cloudflare` instead of `cf`).
  Delete it; fold the one useful thing (the compose YAML skeleton) into
  `add-new-service.md`. Update the docs index (coordinate with task 14).

## Affected files
- `docs/backups/disaster-recovery.md` (rewrite of steps 1, 4, USB note)
- `docs/backups/migrating-between-hosts.md` (replace with redirect stub)
- `docs/operations/storage-replacement.md` (new)
- `docs/backups/overview.md`, `docs/backups/hetzner.md` (repo-string
  consistency)
- `docs/reference/service-template.md` (delete),
  `docs/reference/add-new-service.md` (absorb skeleton)
- `docs/README.md` (index updates)

## Testing plan
- Every command in the touched docs is copy-paste-executable (paths exist,
  flags real). Dry-read as the "stressed future me": each step says what
  success looks like.
- `grep -rn 'solosoyfranco\|/etc/domum/\|Raspberry Pi OS' docs/` → zero hits.
- Index check from task 14's script (every doc linked, every link resolves).

## Rollback strategy
Docs only — revert.

## Dependencies
- Task 02 (URL canonicalization decision) — needs the same answer.
- Task 22 changes the shape of disaster-recovery.md; if 22 is not yet done,
  still fix the wrong commands now and let 22 do a second, smaller pass.
  Correct-but-manual beats wrong-but-manual today.

## Risks
None (documentation).

## Estimated complexity
Medium (~14k tokens, mostly writing the storage runbook).

## Suggested order
Early in the recovery phase — before or alongside task 22. The restore
command fix (item A1) should not wait for anything.
