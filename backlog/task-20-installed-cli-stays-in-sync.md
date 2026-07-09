# Task 20 — Keep the installed CLI (and units) in sync with the repo

## Objective
Eliminate the silent staleness window where the repo is updated but the
binaries and systemd units that production actually executes are not.

## Background / current behavior
- `install.sh` **copies** `bin/domum-core` and `bin/domum-core-backup` to
  `/usr/local/bin/` (`install -m 0755`).
- Systemd timers execute `/usr/local/bin/domum-core ...` (see `systemd/*.service`).
- `bin/domum-core`'s `backup_bin()` prefers `/usr/local/bin/domum-core-backup`
  over the repo copy.
- `sudo domum-core update` (`repo_update()`) does `git fetch` +
  `reset --hard origin/main` — and **stops there**. It does not reinstall the
  binaries or the unit files.

Net effect: after the documented update flow (`domum-core update`), the repo
contains the new CLI but every timer, every `domum-core` invocation, and even
`backups run`'s restic stage keep executing the **old** code until someone
remembers to re-run `install.sh`. A bug fixed in git can keep firing nightly
for months. This also breaks the mental model "git is the source of truth."

Systemd unit files have the same problem one layer up: edits to `systemd/*`
only land after `sudo domum-core schedule install-maintenance` is re-run.

## Desired behavior
One update command leaves the host fully converged: repo, binaries, and
installed unit files all match the checked-out commit.

## Recommended approach (simplest reliable)
**Symlink the binaries; make `update` refresh units.**

1. In `install.sh`, replace the two `install -m 0755` copies with:
   ```bash
   ln -sf "${INSTALL_DIR}/bin/domum-core"        "${BIN_CORE}"
   ln -sf "${INSTALL_DIR}/bin/domum-core-backup" "${BIN_BACKUP}"
   ```
   (Ensure `chmod 0755 "${INSTALL_DIR}"/bin/*` first; git preserves the
   executable bit, but be explicit.)
   The `domum` shim can also become a symlink to `bin/domum` (task 02 already
   deduplicates the shim — coordinate).
2. Symlinks make binaries self-updating on `git pull`. Unit files cannot be
   symlinked safely by policy (systemd reads them at daemon-reload), so in
   `repo_update()` after the reset add:
   ```bash
   if ! diff -rq "$DOMUM_DIR/systemd" <(installed units) ...; then
     warn "systemd/ changed — run: sudo domum-core schedule install-maintenance"
   fi
   ```
   Minimum: detect + warn. Better: re-run the install-maintenance copy
   automatically (it never enables anything, so it is safe) and
   `systemctl daemon-reload`.
3. `ConditionPathExists=/usr/local/bin/domum-core` in units still passes with
   a symlink — verify once on the host.

### Alternative considered (rejected)
Having `repo_update()` re-copy the binaries keeps copies but adds a second
code path that can drift; symlinks delete the problem instead of managing it.
Trade-off to note in the commit: with symlinks, a **broken** repo state
immediately breaks the installed CLI (no "last good copy"). Acceptable here
because CI gates `bash -n`/shellcheck before anything reaches `main`, and
`git reset --hard origin/main` only moves to pushed commits.

## Affected files
- `install.sh`
- `bin/domum-core` (`repo_update()`, optionally `backup_bin()` comment)
- `docs/operations/cli-cheatsheet.md`, `docs/getting-started/install.md`
  (one line each: binaries are symlinks)

## Testing plan
- On the host after applying: `readlink -f /usr/local/bin/domum-core` points
  into `/opt/domum-core`; `sudo domum-core --help` works; a systemd unit
  (`systemctl start domum-core-checkup.service`) runs.
- Edit a comment in `bin/domum-core` on a branch, `domum-core update`-equivalent
  pull, confirm the change is live without reinstall.
- Change a unit file, run `domum-core update`, confirm the warning (or the
  auto-reinstall) fires.

## Rollback strategy
Re-run the old `install.sh` (copies) — symlinks are replaced by copies with
the same `install -m 0755` commands. No state involved.

## Dependencies
Coordinate with task 02 (installer edits, shim) — same files, one PR is fine.

## Risks
Low. Watch for: root-squash or noexec on `/opt` (not the case here), and the
"broken repo = broken CLI" trade-off documented above.

## Estimated complexity
Small (~6k tokens).

## Suggested order
Right after tasks 01–04 + 19 — it makes every later fix actually reach
production automatically.
