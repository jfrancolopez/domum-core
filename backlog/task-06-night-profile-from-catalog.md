# Task 06 — Rebuild the night profile on the service catalog

## Objective
Eliminate the duplicated, drifted compose-file selection logic in
`bin/night-profile.sh` by driving the night profile through the main CLI's
service catalog.

## Files involved
- `bin/domum-core` — add a small `night up|down` subcommand; `schedule_install()`
- `bin/night-profile.sh` — delete after migration
- `install.sh` (no change expected; verify)
- `docs/operations/cli-cheatsheet.md`, `docs/operations/maintenance-timers.md`

## Reason
`night-profile.sh` hand-maintains an if-chain of compose files that has
already drifted from `service_catalog()`: it omits `zwave-js-ui`, `mariadb`,
`music-assistant`, `actual-budget`, `vaultwarden`, and `obsidian-sync`
despite its own comment saying "we include all enabled to keep networks
consistent". Any future service addition must be remembered in two places.
The main CLI already has `compose_cmd` + `--profile night` (see
`domum_night_autostop`), so the standalone script is pure duplication.

## Implementation plan
1. Add to `bin/domum-core`:
   ```
   night_cmd() {
     need_root; load_cfg; export_env_for_compose
     case "${1:-}" in
       up)   compose_cmd --profile night up -d ;;
       down) compose_cmd --profile night stop ;;
       *) die "Usage: domum-core night {up|down}" ;;
     esac
   }
   ```
   plus a `night)` dispatch entry and a usage line.
2. In `schedule_install()`, change the two ExecStart lines to
   `/usr/local/bin/domum-core night up` / `... night down` and drop the
   `install -m 0755 .../night-profile.sh` step.
3. Delete `bin/night-profile.sh`. Have `schedule_install` (or the commit
   message) note that stale `/usr/local/bin/domum-night-profile` copies can
   be removed; `schedule_remove` already deletes it.
4. Update the two docs pages that mention the night profile.

## Testing plan
- `bash -n` + shellcheck pass; CI shellcheck job no longer scans the deleted file.
- On the host: `sudo domum-core night down && sudo domum-core night up`
  behaves like the old timer actions (only night-profile services affected).
- `sudo domum-core schedule install` writes units pointing at the new command;
  `systemctl cat domum-night-up.service` confirms.

## Risk
Medium — touches systemd units that start/stop production containers.
Mitigate: run `night up`/`night down` manually before re-enabling timers.
Note `ENABLE_NIGHT_PROFILE=0` in the current live config, so exposure is low.

## Rollback
Revert the commit and re-run `sudo domum-core schedule install` (old script
returns).

## Dependencies
None.

## Estimated complexity / token size
Medium / ~10k tokens.

## Suggested order
6.
