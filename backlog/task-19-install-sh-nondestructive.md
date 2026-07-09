# Task 19 — Make install.sh non-destructive (remove the `rm -rf` landmine)

## Objective
`install.sh` must never delete data. Today it can destroy a restored system
during the exact disaster-recovery scenario it exists to support.

## Background / current behavior
`install.sh` lines 27–38:

```bash
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  # fetch / warn / pull  (safe)
else
  rm -rf "${INSTALL_DIR}"        # <-- deletes ANYTHING at /opt/domum-core
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi
```

If `/opt/domum-core` exists but is **not** a git checkout, the installer
silently wipes it. Ways this bites:

1. **Disaster recovery ordering mistake.** The DR runbook says "install first,
   restore second". If a stressed operator restores restic data to
   `/opt/domum-core` first (a completely natural move) and then runs the
   `curl | bash` install command, the installer deletes every restored byte.
   The restore then has to be repeated from (possibly slow, offsite) backup.
2. **Partial migrations.** The 2026 USB-SSD→NVMe migration was done with
   rsync. An rsync of the tree *without* `.git` (e.g. `--exclude=.git`, or a
   copy of only `compose/`) followed by install.sh = data gone.
3. Any manual scp/untar of config/data to the install dir before installing.

This directly contradicts the CLI's own stated rule ("never delete existing
files") and is the single most dangerous line in the repository.

## Desired behavior
- `INSTALL_DIR` missing → clone (unchanged).
- `INSTALL_DIR` is a git repo → current fetch/pull logic (unchanged).
- `INSTALL_DIR` exists, is **not** a git repo, and is **non-empty** → abort
  with a clear message telling the operator to move it aside, e.g.:

  ```
  ERROR: /opt/domum-core exists but is not a git checkout.
  Refusing to delete it. If this is restored data, move it aside first:
      sudo mv /opt/domum-core /opt/domum-core.pre-install-$(date +%Y%m%d)
  then re-run this installer and merge your data back afterwards.
  ```
- `INSTALL_DIR` exists, not a git repo, but empty → `rmdir` (safe) and clone.

## Implementation plan
1. Replace the `rm -rf` branch:
   ```bash
   elif [[ -d "${INSTALL_DIR}" ]]; then
     if [[ -z "$(ls -A "${INSTALL_DIR}")" ]]; then
       rmdir "${INSTALL_DIR}"
       git clone "${REPO_URL}" "${INSTALL_DIR}"
     else
       echo "ERROR: ... (message above)" >&2
       exit 1
     fi
   else
     git clone "${REPO_URL}" "${INSTALL_DIR}"
   fi
   ```
2. Update `docs/backups/disaster-recovery.md` step 1 with one sentence:
   "install.sh refuses to overwrite a non-git /opt/domum-core; restore data
   only *after* the installer has run" (task 26 does the full doc pass; this
   sentence can land with either task).

## Affected files
- `install.sh`
- `docs/backups/disaster-recovery.md` (one sentence; coordinated with task 26)

## Testing plan
- `bash -n install.sh`; `shellcheck install.sh`.
- In a container/VM:
  - fresh dir absent → clones fine;
  - `mkdir -p /opt/domum-core && touch /opt/domum-core/file` → installer
    aborts with the message, file intact;
  - empty dir → clones fine;
  - existing git checkout → behaves as before.

## Rollback strategy
Revert the commit. There is no state migration; the change only removes a
deletion path.

## Dependencies
None. Pairs naturally with task 02 (repo URL fix) — same file, do together.

## Risks
None meaningful. The only behavior lost is "installer silently replaces a
non-git directory", which is precisely the bug.

## Estimated complexity
Trivial (~4k tokens).

## Suggested order
Immediately — with tasks 01–04 in the first correctness batch.
