# Task 44 — Weekly report: monthly/yearly averages from history

## Status — ✅ done 2026-07-17 (operator-requested)

## Objective
Power (and the other tracked metrics) should show an average over time,
not just the moment-in-time snapshot: a month average now, a year figure
once 12 months of data exist, and the cost estimate based on the average
rather than one reading. Operator constraint: super simple, no new
tracking machinery.

## What was done
- **No new file, no new timer** — reused `report/history.csv`. It gained
  a 7th column `watts` (each report run stores the PMIC reading it
  already takes). The canonical header is now always rewritten instead of
  copied from the old file, so schema additions migrate old files
  automatically; old 6-field rows simply have an empty watts column and
  are skipped by the numeric filters.
- `report_history_avg <col> <cutoff>` — mean + sample count of a column
  over rows since an ISO cutoff date (ISO strings compare as text; GNU
  `date -d` with a BSD `-v` fallback for the dev-Mac harness). Returns
  nothing under 2 samples — an average of one reading is just the
  reading.
- POWER section: `Month average ~2.0 W (5 samples)` (trailing 30 days),
  `Year average ~2.2 W` only once the oldest row is ≥350 days old, and
  the `Running cost` line now uses the month average when available,
  falling back to the live snapshot.
- TRENDS lines each gained `(avg N)` — the trailing-30-day average of
  that metric — plus a new `Power draw` sparkline line from the new
  column.

## Decisions & rejected alternatives
- **Rejected a dedicated sampling timer/service** (daily or hourly power
  logging): more moving parts for marginal accuracy on an appliance that
  draws a near-constant ~2 W. The averages are built from report runs
  (weekly timer + any manual runs), and the sample count is printed so
  the reader can judge the basis. Revisit only if the operator wants
  tighter data.
- Averages show sample counts / appear only at ≥2 samples — never imply
  precision the data doesn't have (same honesty rule as the rest of the
  report).
- History cap stays 120 rows: at one row/day max that is ~4 months if
  run daily, ~2.3 years at the weekly cadence — enough for the year
  mark under normal operation.

## Affected files
`bin/domum-core`, `docs/operations/weekly-report.md`.

## Testing performed
Off-Pi harness: old-format 6-column file migrates in place; month
average math verified (5 samples → 2.0 W); year line gated correctly
(absent under 12 months of span, correct value with 360-day-old data);
cost switches from snapshot to month average; trends `(avg)` suffixes
and the Power draw sparkline render within iPhone line width. Pi check:
next `report weekly --stdout` should show the watts column appearing in
`/var/lib/domum-core/report/history.csv`.

## Rollback
Revert the commit. Old files keep working (extra column is ignored by
prior code); no state migration needed in either direction.
