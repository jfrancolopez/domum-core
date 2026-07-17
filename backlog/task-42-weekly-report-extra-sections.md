# Task 42 — Weekly report: extra content sections (operator to pick)

## Status — ✅ done 2026-07-16 (operator picked "all that make sense")
- Section 1 (sparklines): shipped — `report_trends`/`report_sparkline`/
  `report_trend_line`. Sparkline levels are computed as ASCII digits in
  awk and mapped to glyphs in bash (multibyte `substr()` is
  locale-dependent). Shows "still collecting" until 2 history rows exist.
- Section 2 (NVMe): shipped — `report_drive_health`, plain-language lines
  plus one derived "In short: roughly N years of life left" sentence
  ((100−wear)/wear × power-on-hours, capped at "10+"). Skips silently
  without smartctl/device.
- Section 3 (power): shipped — `report_power`, V×A summed across PMIC
  rails, "(approx)" label, optional cost line from REPORT_KWH_RATE/
  REPORT_CURRENCY (documented in the overlay example). Skips silently
  without vcgencmd/PMIC.
- Section 4 (image rot table): **resolved as unnecessary** — task 36's
  `image_rot_check` already runs in checkup and its warnings flow into
  the report's FINDINGS section with plain wording ("manual pin review
  due"). A weekly table of every image age would duplicate that data and
  add noise for a non-technical reader. Do not re-propose unless the
  findings path proves insufficient.
- Verified off-Pi with stubbed smartctl/vcgencmd/history.csv and browser
  render at iPhone + laptop widths; hardware-path check on the Pi remains
  (run `report weekly --stdout` there once).

## Objective
Add more *useful* information to the weekly report without hurting its
under-a-minute readability. Each section below is independent; the operator
picks which to add. Implement picked sections one at a time, in the order
listed. All render through the existing text renderer (task 41's HTML
wrapper picks them up automatically — new sections need zero HTML work).

## Background
Task 25's round-3 spec already scoped these; task 41 shipped the rendering
layer only. Two config keys are already parsed by `load_cfg` and currently
unused: `REPORT_KWH_RATE`, `REPORT_CURRENCY` (power cost line), and
`REPORT_TRAEFIK_REQUESTS=0` (gate for the rejected-by-default requests
section). `smartmontools` is already in `HOST_REQUIRED_PACKAGES`.

## Candidate sections, in suggested order

### 1. Eight-week sparklines (best value/effort — pure rendering)
`$STATE_ROOT/report/history.csv` already appends one row per run
(disk %, mem %, temp, containers, journal errors). Render a `TRENDS`
section with Unicode sparklines (`▁▂▃▄▅▆▇`) per metric, e.g.
`Temp °C   ▃▃▄▅▄▃▃▂ 52`. Zero new state. Note: with fewer than ~3 rows
the line is flat — either gate on row count or accept it. The sparklines
ARE the retro aesthetic; no TSDB, no Grafana (rejected in task 25).

### 2. NVMe health (`smartctl -A /dev/nvme0`)
Wear %, TBW, temperature, spare — plus one derived plain sentence
("2% worn after 8 months → roughly 9+ years at this rate", from wear %
vs. power-on hours). Skip the section cleanly if smartctl or the device
is absent. Read-only; runs as root already.

### 3. Measured power draw (`vcgencmd pmic_read_adc`)
Sum V×A across PMIC rails → board watts, labeled "approx". Optional cost
line from `REPORT_KWH_RATE` + `REPORT_CURRENCY` (both unset ⇒ omit the
line). If vcgencmd/PMIC is absent, skip the section — never estimate
(decided in task 25).

### 4. Image rot table (depends on task 36 D5)
Per service: image build age vs. tier threshold — the "review this pin"
nag surface. Blocked until task 36's rot data exists; do not build a
parallel age probe here.

### Recorded as rejected (do not re-propose)
Per-service request counts: requires enabling Traefik access logs =
constant NVMe writes all week for one low-decision number. Stays off
behind `REPORT_TRAEFIK_REQUESTS=0` (task 25 decision).

## Affected files (per section)
`bin/domum-core` (one small `report_*` helper + a `report_hdr` block in
`report_render_weekly`), `docs/operations/weekly-report.md`. Section 3
additionally documents the two config keys in
`config/domum-backup.conf.example`.

## Testing plan (each section)
`sudo domum-core report weekly --stdout` on the Pi (sections source
Pi-only hardware: PMIC, NVMe); confirm the section renders, then one real
send and a glance at Gmail mobile. Absence paths (no smartctl, no PMIC)
verifiable off-Pi.

## Rollback
Each section is an independent, additive block — revert its commit.

## Risks
Low. All read-only probes of things the host already exposes.

## Complexity
Small per section; sparklines and NVMe are the biggest wins.
