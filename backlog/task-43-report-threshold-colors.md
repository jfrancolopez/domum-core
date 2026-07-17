# Task 43 — Weekly report: escalating attention colors on values

## Status — ✅ done 2026-07-17 (operator-requested)

## Objective
Numeric values in the report that approach trouble escalate visually in
three steps (operator's example: disk 70% → notice, 80% → stronger,
90% → immediate attention), in a way that fits the dark phosphor theme
and also survives in the plain-text fallback.

## What was done
- `report_flag <value> <soft> <strong> <crit>` in `bin/domum-core`
  appends ` ▴` / ` ▲` / ` ✗` to a value line (nothing below the soft
  threshold). Floats are truncated to integers; non-numeric input
  no-ops. The glyph IS the severity decision — made once, in the text
  renderer.
- The HTML renderer already painted whole lines containing `▲` (amber
  bold) and `✗` (red bold); one new case paints `▴` lines soft gold
  `#c2a35f`, unbolded. Escalation: pale-green normal → soft gold →
  amber bold → red bold.
- Applied thresholds (soft/strong/crit):
  disk % used 70/80/90 (operator's numbers); memory % 75/85/93;
  CPU temp °C 65/72/80 (Pi 5 firmware-throttles ~85); NVMe temp °C
  55/65/70; NVMe wear % 70/85/95.
- SYSTEM label column narrowed 20→18 chars so flagged lines still fit an
  iPhone (375px, 13px mono ≈ 44 chars) without wrapping.

## Decisions & rejected alternatives
- **Flags are visual only.** They do NOT feed `checkup_add`, FINDINGS,
  or the subject-line verdict — checkup remains the single source of
  verdict truth. Wiring them in would create a second policy engine
  (rejected; principles doc "one source of truth per fact").
- **Glyph-in-text over HTML-only styling**: keeps text and HTML tellings
  identical and required no new HTML parsing — the renderer colors by
  glyph, which it already did for `▲`/`✗`.
- `▴` (U+25B4) chosen for the soft level: same triangle family as `▲`,
  renders in Apple Mail/Gmail, visually quieter.

## Affected files
`bin/domum-core`, `docs/operations/weekly-report.md`.

## Testing performed
Boundary unit test (69/70/79/80/89/90 + floats + junk input) and browser
render at iPhone width showing all four states on one screen. Pi
verification: none needed beyond a normal `report weekly --stdout`
(thresholds are data-independent).

## Rollback
Revert the commit; the flags are pure rendering.
