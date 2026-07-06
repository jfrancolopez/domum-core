# Task 01 — Untrack the live config/domum.conf

## Objective
Stop tracking the live host configuration in git so the repo matches its own
documented contract ("Live config is local-only").

## Files involved
- `config/domum.conf` (currently tracked — should not be)
- `config/domum.conf.example` (stays; canonical)
- `.gitignore` (already ignores it; no change expected)

## Reason
`config/domum.conf` is tracked despite being listed in `.gitignore`
(gitignore never untracks already-committed files). It contains the real
domain, contact email, and LAN IP, and it has drifted from the example
(stale comments referencing removed docs like `docs/OBSIDIAN-SYNC.md`).
`install.sh` even prints a warning about this exact situation (lines 82–87).
Everything downstream (installer, `configure` wizard, `init`) assumes the
live file is local-only.

## Implementation plan
1. Diff `config/domum.conf` against `config/domum.conf.example`; port any
   *setting* present only in the live file into the example as a commented
   default (there should be none — verify).
2. `git rm --cached config/domum.conf` and commit. Do NOT delete the file
   from disk — on the Pi it is the live config.
3. Confirm `.gitignore` line `config/domum.conf` keeps it ignored afterwards.
4. On the Pi, after the next `git pull`: verify the file survived
   (`git rm --cached` + pull can delete it on other checkouts — warn the
   operator in the commit message to check `config/domum.conf` still exists
   and re-copy from the example if not).

## Testing plan
- `git ls-files config/` shows only `*.example` files.
- `git status` clean with `config/domum.conf` present on disk.
- `sudo domum-core configure --validate` still passes on the host.

## Risk
Low in the repo; **medium on the host at pull time** — a `git pull` on a
checkout where the file is tracked will remove it. Mitigate with a loud
commit message and by checking the Pi right after the first pull.

## Rollback
`git revert` the commit; recreate the live file from the example.

## Dependencies
None.

## Estimated complexity / token size
Trivial / small (~5k tokens).

## Suggested order
1 — do this first; several later tasks touch config docs.
