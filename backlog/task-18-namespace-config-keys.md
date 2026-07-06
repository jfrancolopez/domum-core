# Task 18 — FUTURE: Namespace config keys with DOMUM_ prefix  [shared-philosophy]

> **Future idea.** Cosmetic-leaning; only worth doing bundled with other
> config-touching work (e.g. task 17), never as a standalone churn commit.

## Objective
Align generic config key names with the sibling repo's namespaced style:
`STATE_ROOT` → `DOMUM_STATE_ROOT`, `LOG_DIR` → `DOMUM_LOG_DIR` (the sibling
uses `DOMUM_STATE_ROOT`, `DOMUM_LOG_DIR`, `DOMUM_DATA_ROOT`).

## Files involved
- `bin/domum-core`, `bin/domum-core-backup` (read sites + defaults)
- `config/domum.conf.example`
- Live conf on the host (operator edit or back-compat shim)

## Reason
Unprefixed names like `STATE_ROOT` and `LOG_DIR` are sourced into a bash
process where they can collide with anything else sourced later, and they
read as generic rather than owned. The sibling repo prefixes everything.
Value is consistency between siblings and grep-ability — real but small.
That is why this is Future, not Important.

## Implementation plan (when activated)
1. In `load_cfg()` accept both spellings, new one wins:
   `STATE_ROOT="${DOMUM_STATE_ROOT:-${STATE_ROOT:-/var/lib/domum-core}}"`
   (keep internal variable names unchanged to avoid a 200-line diff).
2. Update `config/domum.conf.example` to the new names.
3. Docs mention the alias; live conf can migrate lazily. Never break an
   existing conf — the alias stays permanently (it is 2 lines).

## Testing plan
- Host with old names in live conf: `configure --show`, `checkup`,
  `backups run --dry-run` all resolve identical paths.
- Fresh install from new example: same paths.

## Risk
Medium if done carelessly (paths silently changing = backups/state landing
elsewhere). The alias approach reduces it to low.

## Rollback
Revert; old names still work because they never stopped working.

## Dependencies
Best bundled with task 17's config edits.

## Estimated complexity / token size
Small–medium (~7k tokens).

## Suggested order
18 — last.
