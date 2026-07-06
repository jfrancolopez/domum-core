# Task 02 — Fix install.sh repo URL and duplicate `domum` shim

## Objective
Make a fresh `curl | sudo bash` install clone the correct repository, and keep
exactly one implementation of the `domum` back-compat shim.

## Files involved
- `install.sh`
- `bin/domum`
- `README.md` (verify only)

## Reason
Two inconsistencies:
1. `install.sh` line 4: `REPO_URL_DEFAULT="https://github.com/solosoyfranco/domum-core.git"`,
   but the actual remote and the README both use
   `https://github.com/jfrancolopez/domum-core`. A fresh install on a new
   host clones the wrong (or stale) repo. The sibling repo already uses the
   `jfrancolopez` URL.
2. The `domum` shim exists twice with different logic: `bin/domum` (searches
   `/usr/local/bin/domum-core`, then a repo-relative fallback) and a heredoc
   inside `install.sh` (lines 44–50) that generates a simpler one. Duplicated
   logic that can drift.

## Implementation plan
1. Change `REPO_URL_DEFAULT` to the `jfrancolopez` URL (confirm with
   `git remote -v` first — if `solosoyfranco` is an intentional mirror,
   document that in a comment instead and keep whichever is canonical).
2. In `install.sh`, replace the heredoc shim generation with
   `install -m 0755 "${INSTALL_DIR}/bin/domum" "${BIN_SHIM}"` so `bin/domum`
   is the single source of truth.
3. Optionally have `install.sh` also install `bin/night-profile.sh`? No —
   leave it; `schedule install` owns that (note the boundary in a comment
   only if unclear).

## Testing plan
- `bash -n install.sh` and `shellcheck install.sh` pass.
- On a scratch VM/container: run `install.sh` end-to-end; `domum --help`
  and `domum-core --help` both print usage.

## Risk
Low. The shim is a passthrough; the URL change only affects fresh installs.

## Rollback
Revert the commit.

## Dependencies
None.

## Estimated complexity / token size
Trivial / small (~5k tokens).

## Suggested order
2.
