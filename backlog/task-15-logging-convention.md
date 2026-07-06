# Task 15 — Unified logging convention  [shared-philosophy]

## Objective
One logging convention across `bin/domum-core` and `bin/domum-core-backup`:
prefixed, timestamped where it matters, and captured to `$LOG_DIR` for
timer-driven runs.

## Files involved
- `bin/domum-core` — `log()`, `warn()`, `die()`
- `bin/domum-core-backup` — `log()`, `die()`

## Reason
Current drift:
- `domum-core`: `[domum-core] msg`, no timestamp, stdout only.
- `domum-core-backup`: `[ISO-timestamp] msg`, tee'd to `$LOG_DIR/backup.log`,
  and — oddly — everything goes to **stderr** (`>&2` on `log()`).
When a systemd timer runs `backups run`, half the output has timestamps and
half doesn't, and journal vs. file coverage differs by which script emitted
the line. For a box you debug over SSH after the fact, consistent logs are a
reliability feature, not style.

Keep it minimal — do not build a logging framework:

## Implementation plan
1. Pick the convention (recommend):
   `log()  { echo "[$(date +%H:%M:%S)] [domum-core] $*"; }`
   `warn()` same to stderr with `WARN:`; `die()` unchanged.
   Full ISO timestamps stay in the backup script's file log.
2. In `domum-core-backup`, send informational `log()` to stdout (keep the
   tee to `$LOG_FILE`), reserve stderr for warnings/errors — systemd
   captures both, but interactive `--snapshots` output currently interleaves
   confusingly.
3. Do NOT touch message wording or add levels/colors/verbosity flags.
4. Note in the sibling repo's backlog (when its audit runs) to adopt the
   same helper shape — its CLI currently echoes `[domum-media]` inline
   without helpers in several places.

## Testing plan
- `sudo domum-core checkup` and `sudo domum-core backups run --dry-run`:
  output readable, prefixes consistent, `$LOG_DIR/backup.log` still written.
- shellcheck passes.

## Risk
Low. Only risk is downstream parsing of output — nothing in the repo parses
log lines (verify with a grep for `grep.*domum-core]`).

## Rollback
Revert.

## Dependencies
None.

## Estimated complexity / token size
Small (~6k tokens).

## Suggested order
15.
