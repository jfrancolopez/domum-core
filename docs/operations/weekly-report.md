# Weekly Health Report

`domum-core report weekly` renders a plain-text household health summary: backup
freshness, restore verification, disk/memory/temperature, Docker counts, update
state, journal error count, and the top suggested actions from `checkup`.

It sends at most one report when the systemd timer runs and
`REPORT_EMAIL_ENABLED=1`. With email disabled, the timer exits cleanly without
sending. It does not send extra critical alerts; `checkup` and the journal
remain the normal real-time path.

## Preview

```bash
sudo domum-core report weekly --stdout
```

This prints the report and appends one row to
`/var/lib/domum-core/report/history.csv`.

## Email Dry Run

The report reuses the recovery-pack SMTP settings. Validate the mail settings
without sending:

```bash
sudo domum-core report weekly --dry-run
```

## Enable Email

Edit `/opt/domum-core/config/domum-backup.conf`:

```bash
ENABLE_RECOVERY_EMAIL=1
RECOVERY_EMAIL_TO="you@example.com"
RECOVERY_EMAIL_FROM="you@example.com"
GMAIL_APP_PASSWORD_FILE="/etc/domum-core/secrets/gmail-app-password"

REPORT_EMAIL_ENABLED=1
# Optional; defaults to RECOVERY_EMAIL_TO.
REPORT_EMAIL_TO="you@example.com"
```

The Gmail app password file must exist and be root-readable only:

```bash
sudo install -d -m 0700 /etc/domum-core/secrets
sudoedit /etc/domum-core/secrets/gmail-app-password
sudo chmod 600 /etc/domum-core/secrets/gmail-app-password
```

Send one manual report:

```bash
sudo domum-core report weekly
```

## Enable The Timer

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-weekly-report.timer
systemctl list-timers 'domum-core-weekly-report*'
```

Rollback is simply disabling the timer and setting `REPORT_EMAIL_ENABLED=0`:

```bash
sudo systemctl disable --now domum-core-weekly-report.timer
```
