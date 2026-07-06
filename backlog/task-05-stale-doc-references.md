# Task 05 — Fix stale documentation references

## Objective
Point every reference at the current `docs/` layout (the docs were reorganized
into `getting-started/`, `operations/`, `backups/`, `reference/`, `services/`
but several pointers still use the old flat SCREAMING-CASE names).

## Files involved
- `systemd/domum-core-backups.service` — `docs/SETUP-BACKUPS.md` → `docs/backups/overview.md`
- `systemd/domum-core-updates-check.service` — `docs/UPDATES.md` → `docs/operations/updates.md`
- `systemd/domum-core-security-patches.service` — `docs/SECURITY-PATCHES.md` → `docs/operations/security-patches.md`
- `systemd/domum-core-recovery-email.service` — `docs/RECOVERY-PACK-EMAIL.md` → `docs/backups/gmail-recovery.md`
- `systemd/domum-core-{cleanup-report,recovery-pack,backup-verify,checkup}.service` — `docs/CLI-CHEATSHEET.md` → `docs/operations/cli-cheatsheet.md`
- `config/domum.conf.example` — check for `docs/OBSIDIAN-SYNC.md`, `docs/VAULTWARDEN.md`, `docs/MIGRATION-REMOVED-SERVICES.md` style references → `docs/services/obsidian-sync.md`, `docs/services/vaultwarden.md`, `docs/reference/removed-services.md`
- `compose/productivity/obsidian-sync.yml` comment — `docs/OBSIDIAN-SYNC.md` → `docs/services/obsidian-sync.md`

## Reason
`Documentation=` lines in systemd units and comments in configs are the
first thing an operator reads at 2 a.m. Stale paths cost trust and time.
This is pure drift from the docs reorganization — nothing intentional.

## Implementation plan
1. `grep -rn 'docs/[A-Z]' systemd compose config bin install.sh README.md`
   and fix each hit to the real path (verify each target file exists).
2. Re-run the grep to confirm zero remaining stale references.
3. Note in the commit message that units must be re-installed on the host
   (`sudo domum-core schedule install-maintenance`) for the change to land
   in `/etc/systemd/system`.

## Testing plan
- The grep from step 2 returns nothing.
- Every referenced path exists: script it —
  `grep -roh 'docs/[a-z-]*/[a-z-]*\.md' systemd compose config | sort -u | while read -r f; do [[ -f $f ]] || echo "MISSING $f"; done`
- yamllint passes.

## Risk
None — comments and metadata only.

## Rollback
Revert.

## Dependencies
Task 01 (the live `config/domum.conf` stale comments disappear from git when
it is untracked; only the `.example` needs fixing here).

## Estimated complexity / token size
Small (~6k tokens).

## Suggested order
5.
