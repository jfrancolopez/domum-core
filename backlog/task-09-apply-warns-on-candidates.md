# Task 09 — Warn on pending update candidates during `apply`

## Objective
Close the quiet gap where `updates check` pulls newer images and a later
`domum-core apply` deploys them immediately, silently bypassing the entire
delay-window model.

## Files involved
- `bin/domum-core` — `apply()`, possibly a small helper next to
  `candidate_file_for()`
- `docs/operations/updates.md` (document the behavior)

## Reason
`updates_check()` runs `docker pull` on each service's image tag (the log
line even claims "read-only pull/inspect" — it is not read-only). Because
compose files reference moving tags (`:latest`, `:stable`), once the pull
lands, **any** subsequent `compose up -d` — i.e. every `domum-core apply` —
recreates containers on the new image with no delay window, no backup gate,
and no history entry. The cautious update model can be defeated by the most
routine command in the toolbox. (The sibling repo has the same pull-then-wait
shape, but pins images via config vars, which narrows the window; see
task 10 for the structural fix.)

This task is the cheap, homelab-right mitigation: make `apply` tell you.

## Implementation plan
1. Add a helper `pending_candidates()` that lists candidate files in
   `$STATE_ROOT/update-candidates/` whose service is enabled.
2. At the top of `apply()` (after `load_cfg`), if any exist, print:
   ```
   WARN: pending image updates recorded for: <svc list>
   WARN: 'apply' recreates containers and WILL roll these out now.
   ```
   and require the existing `confirm` (respect `--yes`/`ASSUME_YES`) before
   continuing — or, if prompting inside `apply` feels too intrusive, warn
   loudly and proceed (decide during implementation; warn-only is the
   minimum, prompt is recommended since `apply` is always interactive).
3. On successful apply, clear candidate files for services whose containers
   now run the candidate digest, and write an `updates history` entry
   (`record_update_history ... "applied via apply"`), so history stays honest.
4. Document in `docs/operations/updates.md`: "updates check downloads
   images; apply after check rolls them out."

## Testing plan
- Fabricate a candidate file for an enabled service; `sudo domum-core apply`
  prints the warning/prompt.
- With no candidates: `apply` output unchanged.
- `updates history` shows the apply-path entry after a real rollout.

## Risk
Low–medium: touches `apply`, the most-used command. Keep the new code
strictly additive and early-exit safe; never let the warning path abort a
timer-driven run (timers call `backups run`/`checkup`, not `apply`, so
prompting is safe).

## Rollback
Revert; `apply` returns to prior behavior.

## Dependencies
None. Complements task 10.

## Estimated complexity / token size
Small–medium (~8k tokens).

## Suggested order
9.
