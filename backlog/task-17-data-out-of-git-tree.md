# Task 17 — FUTURE: Relocate runtime data out of the git tree  [shared-philosophy]

> **Future idea. Do not start without an explicit go decision and a fresh
> full backup.** This is the largest structural divergence from the sibling
> repo and the highest-risk item in the backlog.

## Objective
Move live service data (Home Assistant runtime state, MariaDB datadir,
Zigbee2MQTT state, Actual Budget SQLite, Vaultwarden data, AdGuard work/conf,
Z-Wave store, ESPHome state, Music Assistant state) out of
`/opt/domum-core/compose/**` into a dedicated data root outside the git
working tree, mirroring the sibling's durable-storage layout
(`DOMUM_DATA_ROOT=/srv/data` there; on the Pi likely
`/var/lib/domum-core/data` or `/srv/data`).

## Files involved (eventually — split per service before executing)
- Every compose file with a bind mount under `/opt/domum-core/compose/...`
- `bin/domum-core`: `ha_config_dir()`, `actual_data_dir()`,
  `backup_src_dir_for()`, `service_catalog()` docs
- `bin/domum-core-backup`: `BACKUP_PATHS` default
- `.gitignore` (shrink the data/exclusion rules that exist only because data
  lives in-tree)
- `docs/backups/*`, `docs/reference/add-new-service.md`

## Reason
Today the repo working tree is simultaneously: git-tracked config
(HA `configuration.yaml`, themes, mosquitto.conf), live container data
(HA `.storage/`, `home-assistant_v2.db`, MariaDB datadir), and deploy target
of `git reset --hard` (`repo_update`). Consequences:
- `git reset --hard` / `git clean -fdx` proximity to live databases is a
  standing foot-gun (mitigated today by nested `.gitignore` files and the
  drift warning — but "the DB survives because it's gitignored" is thin ice).
- Backups must enumerate paths inside the repo (see `BACKUP_PATHS`).
- The sibling repo already solved this ("durable vs disposable storage
  layout"), so converging here is the single biggest step toward the shared
  foundation.

Why future, not now: every service move requires stop → copy → remount →
verify, on a production Pi, with HA the riskiest (recorder DB + .storage).
The current setup works and is backed up. No urgency; do it service-by-service
when there's appetite.

## Implementation plan (when activated)
1. **Design commit first**: pick the data root, document target layout
   (`<root>/<service>/`), how git-tracked HA config coexists with runtime
   state (likely: config stays in repo, runtime dirs move + symlink or HA
   `configuration.yaml` path split — decide explicitly), and the migration
   order (lowest risk first: uptime-kuma → musicassistant → esphome →
   nodered/zwave/z2m → actual/vaultwarden → adguard → mariadb → HA last).
2. One task per service: update compose mount + `backup_src_dir_for` +
   `BACKUP_PATHS`, write the copy/migration steps, run on host in a window,
   `checkup` + service-specific verification, keep the old dir as `.bak`
   for a week.
3. Final task: simplify `.gitignore`, update disaster-recovery docs, align
   variable naming with the sibling (`DOMUM_DATA_ROOT`).

## Testing plan
Per service: container healthy, data visible in app, backup run captures the
new path, restore-plan docs updated and rehearsed for one service.

## Risk
High (live data moves). Mitigations: per-service tasks, backups fresh,
old dirs retained, HA last.

## Dependencies
Tasks 01, 04, 08 done; a verified restic restore (rehearse once).

## Estimated complexity / token size
Large — the design task ~10k tokens; each service task ~8k.

## Suggested order
17 — future, after everything above is stable.
