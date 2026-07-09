# Task 25 — Weekly health report email

## Objective
One email, Sunday morning, readable in under a minute, that answers: is the
Pi healthy, are the backups fresh everywhere, and is anything waiting on me?
No dashboards, no new services, no alerting stack.

## Background — what already exists (reuse, don't rebuild)
- `run_checkup()` already gathers: container state/restarts/health, disk %,
  memory %, Pi temperature + throttle flags, NTP, secrets perms, backup
  target count + freshness, recovery-pack age, dangling images, apt
  security/general counts, reboot-required. `checkup --json` emits it.
- `send_email_with_attachment()` already does SMTP (Gmail smtps/465, secrets
  from files). It hardcodes attachment framing — needs a small refactor to
  send a body-only (or HTML) message.
- Update state: `updates status` table; `update-history/history.log`.
- Backup history: `$STATE_ROOT/backups/history.log`; per-target freshness
  files (task 21); restore-verify state (task 23).
- Uptime: `uptime -p`; journal errors: `journalctl -p err --since -7d`.

So the report is 90% aggregation of existing outputs plus one send function.

## Desired behavior
`sudo domum-core report weekly [--dry-run|--stdout]` renders and emails:

```
Subject: [domum-core] Weekly report — OK (2 warnings)   ← worst level in subject
1. Verdict line: OK / WARNINGS / CRITICAL + one-sentence why.
2. Backups: per destination — last success age, last restic check,
   last restore-verify result, staging artifact counts. Red if stale.
3. System: disk % (/, /opt, state), memory %, temp, throttle flags,
   uptime, NTP.
4. Docker: running/enabled counts (status_counts), restart-loopers,
   unhealthy, failed systemd units (systemctl --failed), timer last-run
   results for domum-core-* units.
5. Updates: pending candidates table (svc, waiting days, ready?),
   apt security/general counts, reboot-required.
6. Journal: count of err+ lines this week + top 3 repeated messages
   (journalctl -p err --since -7d | dedupe). Count only — no log dump.
7. Recommendations: the existing CHECKUP_ACTIONS list, max 5 items.
```

Format decision: **simple inline-styled HTML** (one `<table>` per section,
green/amber/red status dots via colored ● characters work in plain text too).
Implementation guard: build the plain-text version first; HTML is a wrapper
around the same strings. If the HTML grows past ~100 lines of heredoc,
ship plain text — readability of the code beats prettiness of the mail.
No external templating, no images, no charts.

Anti-alert-fatigue rules:
- Exactly one email per week. No "all clear" daily mails, no per-event mails.
- CRITICAL findings do not trigger extra emails from this feature (checkup's
  timer + journal remain the real-time path; if push alerting is ever wanted,
  that is a separate decision — resist bundling it here).
- Subject always contains the verdict so triage happens in the inbox list.

## Implementation plan
1. Refactor `send_email_with_attachment` minimally: extract
   `send_email <subject> <body-file> [content-type] [attachment]` keeping the
   existing function as a thin wrapper (recovery-pack email untouched).
2. New `report_cmd()` in `bin/domum-core`:
   - call `run_checkup` (already populates the arrays),
   - gather the extra sections (each its own small helper: `report_backups`,
     `report_updates`, `report_journal` ...),
   - render text (+ HTML wrapper), send via the SMTP config that recovery
     email already uses (`RECOVERY_PACK_SMTP_*`); reuse — do NOT introduce a
     second SMTP config block. Add `REPORT_EMAIL_ENABLED=0` +
     `REPORT_EMAIL_TO` (default: recovery email TO) to the overlay example.
3. New `systemd/domum-core-weekly-report.{service,timer}` —
   `OnCalendar=Sun *-*-* 08:00`, `Persistent=true`; installed by the existing
   `schedule install-maintenance` glob, enabled manually like the others.
4. Docs: `docs/operations/weekly-report.md` (short) + index entry + cheatsheet
   row.

## Affected files
- `bin/domum-core` (report_cmd + helpers + email refactor + dispatch/usage)
- `config/domum-backup.conf.example` (REPORT_* keys)
- `systemd/domum-core-weekly-report.service`, `.timer`
- `docs/operations/weekly-report.md`, `docs/README.md`,
  `docs/operations/cli-cheatsheet.md`

## Testing plan
- `sudo domum-core report weekly --stdout` — inspect both renderings.
- `--dry-run` validates SMTP config without sending (mirror the existing
  email dry-run behavior).
- Real send to self; check rendering in Gmail (mobile + desktop).
- Temporarily fake a stale heartbeat file → verdict flips to WARNINGS.

## Rollback strategy
Disable the timer; feature is additive and config-gated
(`REPORT_EMAIL_ENABLED=0` default).

## Dependencies
Nice after tasks 21 + 23 (per-target freshness and restore-verify lines make
the backup section honest), but can land before with those lines marked
"n/a".

## Risks
Low. Watch Gmail app-password reuse (same account as recovery email — fine).

## Estimated complexity
Medium (~15k tokens, mostly rendering).

## Suggested order
After the backup-phase tasks; before hygiene work — it is the feedback loop
that watches everything else.
