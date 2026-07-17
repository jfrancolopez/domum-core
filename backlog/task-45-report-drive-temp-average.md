# Task 45 — Weekly report: drive temperature history average

## Status — ✅ done 2026-07-17 (operator-requested)

## Objective
Apply the monthly-average reporting pattern from task 44 to any other useful
weekly-report metric that can safely be tracked without adding new sampling
machinery or growing unbounded state.

## Background
Task 44 added a bounded `report/history.csv` history file with rolling
averages for dashboard-style values. The operator asked to apply the same
metric to anything else in the report where it makes sense. The history file
is already capped to 120 data rows and one row per day, so adding one numeric
column preserves the simple, bounded design.

## Current behavior before this task
Disk, memory, CPU temperature, service count, log errors, and power draw were
tracked in the history file and shown in `TRENDS` with trailing-30-day
averages. NVMe drive temperature appeared only as the live SMART reading in
`DRIVE HEALTH`.

## Desired behavior
Track NVMe drive temperature as another dashboard metric:

- Add it to the bounded history CSV as `drive_temp_c`.
- Show it as a `Drive temp` sparkline in `TRENDS`.
- Add `(avg N°C)` to the `DRIVE HEALTH` drive-temperature line once at least
  two trailing-30-day samples exist.
- Keep the section absent if `smartctl` or the NVMe device is absent; never
  fake a value.

## Implementation
- Refactored the SMART read into `report_nvme_smart`, shared by history
  collection and the `DRIVE HEALTH` section.
- Extended the canonical history header from seven to eight columns:
  `date,disk_root_pct,mem_pct,temp_c,containers_running,journal_errors,watts,drive_temp_c`.
- Added numeric-only drive-temperature history collection from SMART
  `Temperature:`.
- Added `report_trend_line "$hist" 8 "Drive temp" "°C"`.
- Added a trailing-30-day average suffix to the live `Drive temp` line.

## Affected files
`bin/domum-core`, `docs/operations/weekly-report.md`, `backlog/README.md`,
`backlog/task-45-report-drive-temp-average.md`.

## Testing plan
- `bash -n bin/domum-core bin/domum-core-backup install.sh`
- `shellcheck bin/domum bin/domum-core bin/domum-core-backup install.sh`
- `yamllint -c .yamllint.yml .`
- On the Pi after deployment: `sudo domum-core report weekly --stdout`, then
  confirm `/var/lib/domum-core/report/history.csv` has the `drive_temp_c`
  header and the `DRIVE HEALTH` section still renders normally.

## Decisions & rejected alternatives
- Rejected averaging drive wear, available spare, and total data written:
  wear/spare change too slowly for a monthly average to help, and total data
  written is a cumulative counter. Turning it into a write-rate would be a
  different feature.
- Rejected averaging backup ages, restore status, update counts, and
  throttling flags: those are policy or event signals, not dashboard metrics.
- Reused the existing 120-row history cap and did not add any new timer,
  service, database, or cleanup job.

## Rollback
Revert the commit. Existing history files remain safe: older code ignores the
extra column, and newer code tolerates older rows with an empty/missing eighth
column via numeric-only filters.

## Risk
Low. The SMART read already powered `DRIVE HEALTH`; this task only shares it
with history collection and skips cleanly when no value is available.

## Complexity
Small.
