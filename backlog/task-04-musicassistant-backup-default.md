# Task 04 — Add missing BACKUP_MUSICASSISTANT default

## Objective
Ensure Music Assistant is backed up by default, matching the stated policy
that every enabled service is protected out of the box.

## Files involved
- `bin/domum-core` — `load_cfg()` per-service backup defaults (~lines 77–87)
- `config/domum-backup.conf.example` — per-service backup flag list (~line 88)

## Reason
The service catalog wires `musicassistant` to the flag `BACKUP_MUSICASSISTANT`
(line 375), and `run_service_backups` skips any service whose flag is not
`1` (`${!bvar:-0}`). But `load_cfg()` defaults every other `BACKUP_*` flag to
1 and omits `BACKUP_MUSICASSISTANT`, and the example overlay config omits it
too. Net effect: Music Assistant is **silently never backed up** unless the
user hand-adds the flag — contradicting the comment "Default ON so an enabled
service is protected even before the overlay file is edited."

## Implementation plan
1. Add `BACKUP_MUSICASSISTANT="${BACKUP_MUSICASSISTANT:-1}"` next to the
   other defaults in `load_cfg()`.
2. Add `BACKUP_MUSICASSISTANT=1` to `config/domum-backup.conf.example`
   alongside the other per-service flags.
3. Sanity-check the whole catalog for other flag/default mismatches
   (compare column 5 of `service_catalog()` against the `load_cfg` defaults;
   `tailscale`, `traefik`, `uptime-kuma` use `-` intentionally).

## Testing plan
- `sudo domum-core backups run --dry-run` on the host now logs a
  musicassistant staging line instead of "backup disabled".
- `bash -n` + shellcheck pass.

## Risk
Low. Adds a tar of `compose/automation/music-assistant` to the nightly run;
size should be small (config/state only).

## Rollback
Set `BACKUP_MUSICASSISTANT=0` in the live overlay, or revert.

## Dependencies
None. Task 08 later adds an automated guard against this class of bug.

## Estimated complexity / token size
Trivial / small (~4k tokens).

## Suggested order
4.
