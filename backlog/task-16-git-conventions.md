# Task 16 — Git workflow conventions doc  [shared-philosophy]

## Objective
Write down the lightweight git conventions both repos should follow, as a
one-page doc that the sibling repo can copy verbatim.

## Files involved
- `docs/reference/git-workflow.md` (new)
- `docs/README.md` (index entry)

## Reason
History shows three commit-message dialects side by side:
`service: description` ("adguard: compose changes"), conventional-commits
("feat: per-app update controls", "fix: clear shellcheck"), and free-form
("new cli implemented", "Phase 8 — the configure wizard"). None is wrong,
but a shared, *tiny* convention makes `git log --oneline` scannable and
keeps the two repos feeling like siblings. This is documentation only — no
hooks, no commitlint, no CI enforcement (deliberately: one-person homelab).

## Implementation plan
Write ~1 page covering, descriptively (what you already mostly do):
1. Commit style: `<area>: <imperative summary>` where area is a service name
   or `bin|docs|ci|compose|config` — e.g. `mariadb: pin image to 11.4`.
   `feat:`/`fix:` accepted as areas too; don't police it.
2. Branching: work on `main` is fine for solo docs/config; use a short-lived
   branch for anything touching `bin/` or compose, merged after CI is green.
3. Deploy flow (the actual contract): commit → push → SSH →
   `sudo domum-core update` → `sudo domum-core apply` → `checkup`.
4. What must never be committed (live conf, secrets, data dirs) and the
   `git rm --cached` recovery move.
5. A note that domum-core-media follows the same page, with names swapped.

## Testing plan
- Doc renders, index links resolve. Nothing executable.

## Risk
None.

## Rollback
Delete the doc.

## Dependencies
None.

## Estimated complexity / token size
Small (~5k tokens).

## Suggested order
16.
