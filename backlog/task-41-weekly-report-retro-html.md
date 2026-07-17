# Task 41 — Weekly report: retro HTML email + mobile-readable text

## Objective
Implement the rendering half of task 25's "round-3 retro dashboard" spec:
the weekly report email must be pleasant and readable on an iPhone (Apple
Mail/Gmail app) and a laptop, in plain language a household member can
follow, without adding any new service, dependency, or SMTP path.

## Background
Task 25 shipped the plain-text weekly report (`6f97eb6`) and its timer. The
round-3 design spec (recorded in `task-25-weekly-health-report.md`) was not
implemented: the email went out as raw `text/plain`, with a ~140-char-wide
`updates status` table and raw `df -h` output that wrapped badly on phones,
and the restore-verify line dumped a multi-line env file inline.

## What was done (operator-requested, 2026-07-16)
All in `bin/domum-core`, weekly-report section only:

1. **Text renderer** (`report_render_weekly`) — plain-language pass:
   - box-drawing masthead `╔══ DOMUM-CORE // WEEKLY ══ <date> ══╗`,
     `╚══ end of report ══╝` footer, `── SECTION ───` dividers
     (`report_hdr`), `●/▲/✗` verdict glyph (`report_verdict_glyph`);
   - Backups: label + age only ("Last backup   5h ago"); state-file
     contents are no longer echoed (the restore-verify file is an env
     file — its STATUS field is read instead);
   - System: per-mount one-liners ("Disk /  26% used, 41G free") replace
     the raw `df -h` table; throttle flags decoded to "none" when `0x0`;
   - Updates: plain summary ("2 update(s) pending, 1 ready" + one short
     line per pending service) replaces the embedded wide table;
   - Findings/Actions: `✗`/`▲` glyphs, "all clear" wording.
   All lines are built to fit ~44 monospace chars so nothing wraps at
   375px/13px.
2. **HTML renderer** (`report_render_weekly_html`) — wraps the *rendered
   text lines* (the text stays the single source of truth, per task-25
   guard). Email-safe by construction: single 600px column, all styles
   inline, monospace stack, no images/JS/webfonts/remote assets. Verdict
   banner color keys off the glyph; lines containing `✗`/`▲` are
   colorized.
   **Palette (operator revision, 2026-07-16):** dark phosphor terminal —
   paper `#141a15` (deep green-black, deliberately not pure black), body
   `#cfe3cf`, phosphor green `#42e07d` with a soft CRT text-shadow glow on
   the masthead, amber `#e5b567`, red `#ff7a6e`, tinted verdict-banner
   backgrounds. This supersedes task 25's cream-palette decision: the
   operator uses dark mode everywhere and accepted the residual risk that
   some dark-mode email clients re-theme content; `color-scheme: dark`
   meta hints plus `bgcolor` attributes minimize it.
   **Animation:** one blinking terminal cursor `▌` after the masthead boot
   line, via a tiny `<style>` keyframe — progressive enhancement only:
   Apple Mail animates it, Gmail strips the style and shows a solid
   cursor. Rejected anything heavier (GIFs, scanline overlays) — images
   are banned by the spec and the email must stay light.
   Masthead is now a 4-line ASCII box + `>` boot line; box contents are
   kept pure ASCII because printf `%-36s` pads by bytes and multibyte `─`
   inside the field breaks alignment.
3. **Send path** (`report_cmd`): builds `multipart/alternative`
   (text part first, HTML second) and passes it through the existing
   `send_email_body` — its content-type was already a parameter, so no
   email refactor and no second SMTP config. New `--html` flag prints the
   HTML rendering; `--stdout`/`--dry-run` unchanged.
4. Docs: `docs/operations/weekly-report.md`, cli-cheatsheet row, usage().

## Decisions & rejected alternatives (do not re-litigate)
- **HTML parses the rendered text** rather than each section rendering
  twice — enforces the task-25 "text is the source" guard; one place to
  add future sections.
- **`html_escape` uses `sed`, not `${var//…}`**: bash 5.2 (Debian
  bookworm) enables `patsub_replacement` by default, which expands `&` in
  the replacement string to the matched text — `${s//</&lt;}` silently
  produced `<lt;`. Found by rendering in a real browser.
- **Subject stays ASCII** ("Weekly report - OK"). Rejected putting the
  `●/▲/✗` glyph in the subject: raw UTF-8 in headers needs RFC 2047
  encoded-words; not worth the machinery, the verdict word already does
  inbox triage.
- **Rejected** external templating, images, a second SMTP block, and any
  `<style>` usage the email depends on (Gmail strips `<style>`; the only
  one shipped is the optional cursor keyframe). Task 25's "no dark
  background" rule was consciously overridden by the operator — see the
  palette note above; do not flip it back without asking.
- **Kept ASCII-safe fallback**: every glyph used (`─ ╔ ╝ ● ▲ ✗`) renders
  in the plain-text part too, so the fallback loses color, not meaning.

## Affected files
`bin/domum-core`, `docs/operations/weekly-report.md`,
`docs/operations/cli-cheatsheet.md`.

## Testing performed
- `bash -n` + `shellcheck` clean (all four scripts).
- Rendering functions extracted into a harness and fed a realistic sample
  (warnings verdict, `<`/`>`/`&` in journal lines); HTML inspected in a
  browser at 375×812 (iPhone) and desktop width: no horizontal scroll,
  glyphs intact, escaping correct, verdict banner amber/green as expected.
- **Not tested (needs the Pi + real mailbox):** actual multipart send;
  the task-25 acceptance test — send to self, check Apple Mail (iPhone,
  light+dark) and Gmail web. Run:
  `sudo domum-core report weekly --dry-run` then a real send.

## Rollback
Revert the commit. Feature stays config-gated (`REPORT_EMAIL_ENABLED`);
the timer needs no change. Multipart is additive — any client that cannot
parse it still shows the text part.

## Dependencies / follow-ups
Content additions (sparklines, NVMe, power, image-rot) are task 42 —
deliberately excluded here to keep this batch rendering-only.

## Complexity
Small-medium (rendering only, no new state or config keys).
