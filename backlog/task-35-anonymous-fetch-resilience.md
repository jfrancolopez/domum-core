# Task 35 — Update/install must not depend on the operator's SSH identity

## Objective
`curl | bash` (install.sh) and `sudo domum-core update` must keep working
regardless of how the operator has configured the checkout's push remote.
Today both die if `origin`'s fetch URL is SSH, because they run git as root
and root has no GitHub SSH key.

## Background — the real incident (2026-07-10)
On the production Pi, the documented update command failed:

```
[domum] Cloning or updating repo in /opt/domum-core...
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

Root cause chain:
1. The operator implements tasks directly on the Pi and pushes from there,
   so `/opt/domum-core`'s `origin` was switched to the SSH form
   (`git@github.com:jfrancolopez/domum-core.git`).
2. install.sh (existing-checkout branch) and `repo_update()`
   (`bin/domum-core` ~line 342) both run `git fetch --all --prune` — which
   uses the checkout's own remote URL, not `REPO_URL`.
3. Under `sudo bash`, git runs as **root** (`HOME=/root`): the operator's
   GitHub key lives in `~jfranco/.ssh` (stow dotfiles) and `sudo`'s
   `env_reset` drops `SSH_AUTH_SOCK`, so root has no usable identity →
   `Permission denied (publickey)` → `set -euo pipefail` aborts (exit 128).

Same failure would hit a root gitconfig `insteadOf` rewrite to SSH. The
fresh-Pi DR path is unaffected (a fresh clone uses the HTTPS `REPO_URL`),
but "update the live host" is the most-used flow and it must be
identity-free: the repo is public, reads need no credentials.

## Immediate operator fix (applied 2026-07-10; keep for reference)
HTTPS for fetch (anonymous — works for root, timers, DR), SSH for push
(operator's key keeps working):

```bash
sudo git -C /opt/domum-core remote set-url origin https://github.com/jfrancolopez/domum-core.git
sudo git -C /opt/domum-core remote set-url --push origin git@github.com:jfrancolopez/domum-core.git
```

## Desired behavior
When the fetch URL of `origin` is not anonymous-HTTPS, install.sh and
`domum-core update` print a clear warning with the two exact
`remote set-url` commands above **before** attempting the fetch — so a
failure, if it still happens, arrives pre-diagnosed. They do **not** rewrite
the remote themselves (prime directive: never silently change operator
config; the split fetch/push setup is a choice the operator should make once,
eyes open).

## Implementation plan
1. Shared 6-line check (duplicated in both files is fine — install.sh must
   stay standalone since it runs before the repo exists):
   ```bash
   fetch_url="$(git -C "$DIR" remote get-url origin 2>/dev/null || true)"
   case "$fetch_url" in
     https://*) : ;;
     *) warn "origin fetch URL is '$fetch_url' — running as root, SSH auth will likely fail."
        warn "Recommended (anonymous fetch, SSH push):"
        warn "  git -C $DIR remote set-url origin https://github.com/jfrancolopez/domum-core.git"
        warn "  git -C $DIR remote set-url --push origin git@github.com:jfrancolopez/domum-core.git" ;;
   esac
   ```
   In install.sh use `echo "[domum] WARN: ..."` to match its style.
2. Add the split-remote recipe to `docs/reference/git-workflow.md` (task 16;
   if not yet written, put it in `docs/getting-started/install.md`'s
   troubleshooting or the doc that exists — do not create a new doc for it).
3. While there: `repo_update()` and install.sh both fetch with `--all` —
   `origin` alone is sufficient and avoids surprises from any extra remotes;
   change to `git fetch --prune origin` in both (small, same intent).

## Affected files
- `install.sh`
- `bin/domum-core` (`repo_update()`)
- `docs/reference/git-workflow.md` or `docs/getting-started/install.md`

## Testing plan
- Sandbox: clone the repo, `git remote set-url origin git@github.com:...`,
  run install.sh → warning with the fix commands appears before the fetch
  error; set HTTPS fetch URL → no warning, clean run.
- `bash -n` + shellcheck on both files.
- On the Pi after the operator fix: `sudo domum-core update` and the
  `curl | bash` line both succeed as root.

## Rollback strategy
Revert — the change is a warning plus a narrower fetch; no state.

## Dependencies
None. Complements task 16 (the git-workflow doc is the natural home for the
push-over-SSH recipe).

## Risks
None meaningful. Worst case is a spurious warning for an exotic-but-working
remote (e.g. a local mirror path) — acceptable, it is advisory only.

## Estimated complexity
Trivial–small (~5k tokens).

## Suggested order
Anytime; good filler task.
