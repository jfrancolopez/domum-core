# Task 03 — Fix `--force` delay-window bypass bug in updates

## Objective
Make `domum-core updates apply <app> --force` actually bypass the delay
window, as documented.

## Files involved
- `bin/domum-core` — `candidate_ready_for_apply()` (~line 1343)

## Reason
The function declares `local svc force file ...` but never assigns `force`
from `$2`, then evaluates `(( force == 1 ))`. An unset local evaluates to 0
in arithmetic context, so the early-return never fires and the caller's
`--force` (passed as `$2` at line 1454) is silently ignored. Result: a forced
update is still skipped with "delay window has not elapsed" — the operator
believes force works and it doesn't. (The *backup gate* force path further
down in `updates_apply_one` works; only the delay-window bypass is broken.)

## Implementation plan
1. In `candidate_ready_for_apply()`, add `force="${2:-0}"` right after
   `svc=...`.
2. Read the surrounding code once more to confirm no other caller relies on
   the broken behavior (`updates_apply_one` is the only caller).

## Testing plan
- `bash -n bin/domum-core`, `shellcheck bin/domum-core`.
- On the host (or in a sandbox with a fake candidate file under
  `/var/lib/domum-core/update-candidates/`): create a candidate with
  `FIRST_SEEN_TS=$(date +%s)` and a 7-day delay; verify
  `updates apply <app> --dry-run` skips it and
  `updates apply <app> --dry-run --force` proceeds to the compose pull/up
  dry-run output.

## Risk
Low — one-line fix restoring documented behavior. `--force` remains gated
behind explicit operator intent.

## Rollback
Revert the commit.

## Dependencies
None.

## Estimated complexity / token size
Trivial / small (~4k tokens).

## Suggested order
3.
