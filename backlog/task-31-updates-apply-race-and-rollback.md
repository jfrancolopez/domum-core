# Task 31 — SUPERSEDED by task 36 (2026-07-10)

> **Do not implement this task.** Its two features (digest-verified apply,
> `updates rollback`) are absorbed as sections D2 and D4 of
> `task-36-unattended-update-pipeline.md`, which redesigns the whole update
> pipeline after the 2026-07-10 mariadb incident (pull-free check, scheduled
> apply-auto, tier policy, rot-nagging). Kept for the background analysis
> below.

# Task 31 (historical) — Updates: apply exactly the aged candidate + add `updates rollback`

## Objective
Close the remaining honesty gaps in the cautious-update model: (a) `updates
apply` must deploy the digest that actually aged through the delay window,
not whatever the tag points to at apply time; (b) give the operator a
one-command rollback, since "rollback capability" is a stated priority and
today rolling back a moving tag requires docker archaeology.

## Background / current behavior

### Gap A — apply-time digest race (TOCTOU)
`updates check` records a candidate digest and starts the delay clock.
`updates_apply_one()` then runs:
```bash
run compose_cmd pull "$cs"     # pulls whatever the tag points to NOW
run compose_cmd up -d "$cs"
```
If upstream pushed a newer image after the candidate was recorded, apply
deploys that **un-aged** image. The delay-window model ("a digest must be
stable N days") is enforced for the decision but not the deployment. Related:
`record_update_candidate` does reset the window when it *notices* a new
digest, but `updates check` may not have run between release and apply.

### Gap B — no rollback command
`record_update_history` stores `FROM_IMAGE` (the previous image ID) — the
data needed for rollback exists, but the procedure (retag old ID onto the
tag, `up -d`, don't let the next pull clobber it) lives in nobody's head at
2 a.m.

## Desired behavior

### A. Pin the apply to the candidate digest
In `updates_apply_one`, after the pull:
```bash
new_id="$(docker image inspect "$image_ref" --format '{{.Id}}')"
if [[ "$new_id" != "$CANDIDATE_DIGEST" ]]; then
  warn "$svc: tag now points at a different digest than the aged candidate."
  warn "$svc: recording new candidate and resetting the delay window."
  record_update_candidate "$svc" "$image_ref" "$RUNNING_DIGEST" "$new_id"
  return 0   # unless --force, which proceeds with the new digest, loudly
fi
compose_cmd up -d "$cs"
```
(The candidate file already stores `CANDIDATE_DIGEST` and `IMAGE_REF`; source
it in the function.) This is deliberately the *simple* fix — deploying the
older aged digest by ID is possible (`docker tag <candidate-id> <ref>` before
`up`) but fights the registry model and confuses later pulls; declining +
re-aging is more honest and zero-magic. Document the behavior in
`docs/operations/updates.md`.

### B. `domum-core updates rollback <app> [--dry-run]`
1. Find the most recent `update-history/<app>-*.env` with `RESULT=success`
   and a non-empty `FROM_IMAGE`.
2. Confirm the image ID still exists locally (`docker image inspect`) — if
   pruned, abort with the restore hint (`docker pull` of an older tag is not
   possible for moving tags; state clearly that rollback depends on the old
   image not having been cleaned; consider having `cleanup images` keep the
   last FROM_IMAGE per service — add that guard here: skip candidates that
   appear as FROM_IMAGE in the newest history entry per service).
3. `docker tag "$FROM_IMAGE" "$image_ref"` + `compose_cmd up -d "$cs"`.
4. Record a history entry `RESULT=rollback`, and (important) write a
   candidate-suppression note: the next `updates check` will see the newer
   digest as an update again — that is correct and visible, but the delay
   window restarts, giving the operator time to pin (task 10) or investigate.
5. Usage + docs.

### Interaction with task 10 (image pinning)
Pinned services (MariaDB, HA once task 10 lands) get rollback "for free" by
moving the pin back in config — `updates rollback` should detect a
config-pinned image (`${SERVICE}_IMAGE` set) and print "this service is
pinned; roll back by changing <VAR> and running apply" instead of retagging.

## Affected files
- `bin/domum-core` — `updates_apply_one()`, new `updates_rollback()`,
  `cleanup_images` keep-guard, dispatch/usage
- `docs/operations/updates.md`, `docs/operations/cli-cheatsheet.md`

## Testing plan
- Gap A: fabricate a candidate file whose `CANDIDATE_DIGEST` differs from the
  pulled image (edit the env file) → apply declines + rewrites the candidate;
  `--force` proceeds with warnings; digests match → applies normally.
- Gap B: on the host with a real prior update in history: `updates rollback
  <small-app> --dry-run` prints the plan; real run flips the container to the
  old ID (`docker inspect` confirms); service healthy; `updates history`
  shows the rollback entry.
- `cleanup images --dry-run` no longer lists a FROM_IMAGE id.

## Rollback strategy (of this change itself)
Revert the commit; both features are self-contained functions. A performed
container rollback is undone by `updates check` + `apply <app> --force`.

## Dependencies
- Task 03 (`--force` fix) first — this task's force-paths build on it.
- Coordinates with task 09 (apply warning) and task 10 (pinning); no hard
  ordering, but 03 → 09 → 31 → 10 is the natural sequence.

## Risks
Medium: touches the update path of production services. Mitigations: dry-run
paths for both features, per-app scope, and the backup gate remains in force
for rollbacks of stateful services (a rollback can downgrade a schema —
warn when rolling back mariadb/HA specifically).

## Estimated complexity
Medium (~12k tokens).

## Suggested order
Update-model phase, after tasks 03 and 09.
