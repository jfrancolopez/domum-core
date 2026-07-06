# Task 14 — Docs index completeness pass

## Objective
Make `docs/README.md` list every doc that exists, so the index is trustworthy.

## Files involved
- `docs/README.md`

## Reason
The index omits at least: `backups/migrating-between-hosts.md`,
`reference/hardware-devices.md`, `reference/mariadb-troubleshoot.md`,
`reference/service-template.md`, `operations/maintenance-timers.md`
(verify each — some may be intentionally unlisted). An incomplete index
means docs get rediscovered by grep instead of by reading, and orphaned docs
rot unnoticed.

## Implementation plan
1. `find docs -name '*.md' | sort` vs. links in `docs/README.md`; list the diff.
2. Add missing entries under the right section (or, if a doc is truly
   obsolete, propose deletion in the PR description rather than silently
   removing it).
3. Spot-check that each linked doc's first heading matches its link text.

## Testing plan
- Script check: every `docs/**/*.md` (except README itself) appears exactly
  once in the index; every index link resolves to an existing file.

## Risk
None.

## Rollback
Revert.

## Dependencies
None (do after task 05 to avoid churn).

## Estimated complexity / token size
Trivial (~3k tokens).

## Suggested order
14.
