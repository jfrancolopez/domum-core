# Weekly Health Report

`domum-core report weekly` renders a household health summary in plain
language: backup freshness, restore verification, disk/memory/temperature,
week-by-week trend sparklines, NVMe drive health, measured power draw,
service counts, pending image updates, journal error count, and the top
suggested actions from `checkup`.

Values that deserve attention escalate through three visual levels — `▴`
soft gold (getting warm), `▲` amber (attention), `✗` red (act now) — in
both the text and HTML renderings. Thresholds: disk 70/80/90 % used,
memory 75/85/93 %, CPU temperature 65/72/80 °C, drive temperature
55/65/70 °C, drive wear 70/85/95 %. These flags are visual only; the
verdict in the subject line still comes solely from `checkup`.

Sections degrade honestly rather than guessing:

- **Trends** draws 8-week Unicode sparklines from
  `/var/lib/domum-core/report/history.csv` (one row per day, last run
  wins); the first weeks show "still collecting" until there are two data
  points. Each line also shows a trailing-30-day average once two samples
  exist in that window.
- **Drive health** reads NVMe SMART data (`smartctl`) and adds one plain
  sentence ("roughly 10+ years of life left"); the section disappears if
  the device is absent.
- **Power** sums the Pi 5 PMIC rails for measured watts (labeled approx).
  Each report also stores the reading in the history file, so the section
  grows a "Month average" line (trailing 30 days, with sample count) once
  two readings exist, and a "Year average" once the history spans ~12
  months. Set `REPORT_KWH_RATE` (price per kWh, e.g. `0.177`) in
  `config/domum-backup.conf` to add a yearly cost line like `~$3/year` —
  computed from the month average when available, otherwise the live
  reading. The currency symbol defaults to `$` and can be changed with
  `REPORT_CURRENCY`. No PMIC ⇒ no section, never an estimate.

The email is sent as `multipart/alternative`: a plain-text version (the
source of truth) plus an HTML wrapper styled for phones and Gmail — single
600px column, monospace, dark phosphor-terminal palette (deep green-black
paper, glowing green masthead, amber/red only for findings), `●/▲/✗` status
glyphs, all styles inline, no images or scripts. The blinking terminal
cursor animates in Apple Mail and degrades to a static cursor in Gmail.
Mail clients that prefer HTML show the styled version; everything else
falls back to the text.

It sends at most one report when the systemd timer runs and
`REPORT_EMAIL_ENABLED=1`. With email disabled, the timer exits cleanly without
sending. It does not send extra critical alerts; `checkup` and the journal
remain the normal real-time path.

## Preview

```bash
sudo domum-core report weekly --stdout   # plain-text rendering
sudo domum-core report weekly --html     # HTML rendering (pipe to a file to open in a browser)
```

Either preview appends one row to
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
