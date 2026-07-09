# Task 22 — Guided restore: `domum-core restore` (the DR wizard, right-sized)

## Objective
Turn disaster recovery from "read a runbook and hand-type restic commands"
into one guided command that discovers snapshots, restores data, and walks
the operator to a running system — while staying a plain bash subcommand, not
a framework.

## Background
Current restore surface:
- `domum-core-backup --restore <snap> <dir> [repo]` — thin restic wrapper,
  undocumented gotcha: restic reproduces **absolute paths under** `--target`,
  so `--restore latest /opt/domum-core` nests data at
  `/opt/domum-core/opt/domum-core/...` (the DR runbook currently shows exactly
  this wrong invocation — task 26 fixes the doc; this task fixes the tool).
- `actual restore-plan` / `homeassistant restore-plan` — print manual steps.
- `docs/backups/disaster-recovery.md` — the runbook gluing it together.

The 2026 boot-failure incident showed the weakness: under stress, every
manual step (finding the snapshot, remembering `--target` semantics, restore
order, named-volume re-import) is an error opportunity.

### Right-sizing the original vision
The full vision (bootstrap auto-launches a wizard that probes Hetzner, two
NAS boxes, and USB, then renders a comparison table) is more machinery than a
one-person homelab needs, and it has a bootstrap paradox: on a bare Pi there
are no credentials to probe *anything* until the recovery pack is restored.
The simplification that keeps ~all of the value:

1. **The recovery pack is the entry ticket.** It already contains
   `domum-backup.conf` (all target definitions) and every secret (restic
   passwords, Hetzner SSH key). The operator has it via email/offline copy —
   that is its whole purpose.
2. Given a restored config + secrets, "discover available backups" is just
   `restic snapshots` against each enabled target — code that already exists.
3. USB restore is not a separate source type: a USB disk holds a restic repo
   (see task 24) and appears as one more target.

So the wizard = "unpack recovery pack → pick target → pick snapshot →
restore → reassemble", each step scripted, each step confirmable.

### Entry points (round-2 feedback: evaluate all of them)
The five requested entry points (recovery pack, Hetzner, Buffalo NAS, Unraid
NAS, USB, manual credentials) are not five wizard modes. They factor into
**two credential sources × N uniform targets**:

| Entry point | What it really is |
|---|---|
| Recovery pack | credential source #1: contains config (all target definitions) **and** secrets (restic passwords, SFTP keys). Needs the offline AGE key. Primary path. |
| Hetzner / Buffalo / Unraid | targets — uniform restic repos once credentials exist; the wizard's table step probes whichever are reachable and lists them all |
| USB | a target too: a restic repo on a mounted disk (task 24); zero special handling beyond "enter/confirm the mount path" |
| Manual credential entry | credential source #2, last resort (`restore --manual`): wizard prompts for ONE repo string + restic password, restores `config/` + the recovery-pack directory from that repo, then **pivots to the pack** for the remaining secrets — which still needs the AGE key |

Design consequence: implement two intake functions (pack intake, manual
intake) and one shared everything-else. Do not build per-destination code
paths.

**The hard floor (state it in the docs, prominently):** no wizard design can
remove the need for exactly two things to survive off-Pi — the **AGE private
key** (secrets) and, for the manual path, a **restic password**. Everything
else is recoverable from the repos themselves. Both already fit in a
password manager + printed copy; the docs must say so in one sentence.

## Desired behavior
```
sudo domum-core restore                # interactive, from a fresh install
sudo domum-core restore --pack /path/recovery-pack-*.tar.age --key /path/recovery-age.key
sudo domum-core restore --manual       # last resort: type one repo + password
```
Flow (each step prints what it will do and asks confirm; --yes for rehearsals):
1. **Pack intake:** decrypt + unpack the recovery pack; install `secrets/*` to
   `/etc/domum-core/secrets` (0600 root) and `config/*` to
   `$DOMUM_DIR/config/`. Skippable if config+secrets already present.
2. **Target + snapshot selection:** for each enabled target, try
   `restic snapshots --latest 3` (short timeout); print a simple table —
   target, snapshot ID, date, host. Unreachable targets are listed as such,
   not fatal. Operator picks one (default: newest reachable).
3. **Data restore:** `restic restore <snap> --target /` **after** showing the
   path list (`restic ls`) summary and requiring an explicit `yes`. This is
   the one genuinely dangerous step; alternatively (safer default, slower):
   restore to `/var/lib/domum-core/restore-staging/` then rsync into place
   per top-level path with `--backup --suffix=.pre-restore`. Choose the
   staging approach — it matches the repo's "never overwrite in place" rule.
4. **Reassembly:** re-import named volumes from
   `service-backups/volumes/*.tar.gz` (loop already written in the DR doc —
   move it into the CLI); `docker network` creation via existing
   `ensure_networks`.
5. **Bring-up:** run the safe order (adguard → mariadb → mqtt → radios →
   `apply`), which is just 4 compose invocations already listed in the doc;
   then `checkup` and print the result.
6. **MariaDB data:** offer to load the newest
   `service-backups/mariadb/mariadb-all-*.sql.gz` into the running mariadb
   (this is required — task 21 removes raw datadir from restic). Confirm
   before executing; print the manual command too.
7. **Host finishers (disposable-OS round-2 additions):** print the
   BACKUP-MANIFEST.json summary before step 3 ("restoring: commit X,
   2026-07-12, 14 services") so the operator confirms *what* they are
   restoring, and after bring-up offer to re-enable the systemd timers
   recorded in the manifest's `enabled_timers` (task 33) — the one piece of
   host state a rebuild otherwise silently loses. Both degrade gracefully
   when the manifest is absent (old snapshots).

Also fix `do_restore` in `bin/domum-core-backup` to document/handle the
`--target` semantics (add `--verify` flag pass-through while there).

## Explicitly out of scope
- Auto-launching from install.sh (`install.sh` stays dumb; it may *print*
  "restoring? run: sudo domum-core restore").
- Probing for backups without credentials, QR codes, web UI, progress bars.
- Restoring to a different `DOMUM_DIR`.

## Affected files
- `bin/domum-core` — new `restore_cmd()` (~150–200 lines) + dispatch + usage
- `bin/domum-core-backup` — `do_restore` target-semantics fix
- `docs/backups/disaster-recovery.md` — collapse manual steps into
  "run `sudo domum-core restore`" with the manual path kept as Appendix
  (coordinate with task 26)

## Testing plan
- Dry-form rehearsal on the production Pi is NOT the test bed. Test on any
  Linux box / VM: fake a recovery pack (`recovery-pack create` output from
  the Pi), a local restic repo target, run the full flow, verify services
  come up with restored data.
- On the Pi, test steps 1–2 only (pack intake to a temp dir via env override,
  snapshot listing) — read-only.
- The full end-to-end on real hardware is task 23's rehearsal (first run of
  the restore verification doubles as the wizard's acceptance test).

## Rollback strategy
The staging + `--suffix=.pre-restore` design means every overwritten file has
a sibling copy; a failed restore is recoverable by reversing the rsync. The
command itself is additive — reverting the commit removes it without trace.

## Dependencies
- Task 21 (source-set changes define what restore must reassemble — the
  MariaDB step exists because of it).
- Task 26 should land with or after this (docs describe the command).

## Risks
Medium-high if step 3 were in-place; the staging approach reduces it to
medium. The wizard must never run `git` operations or touch `/etc` outside
the secrets dir.

## Estimated complexity
Large (~20k tokens). The single highest-value item in this backlog.

## Suggested order
After tasks 21 + 26; before task 24 (new destinations plug into a wizard that
already exists).
