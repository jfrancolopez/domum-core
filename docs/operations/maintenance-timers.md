# Maintenance timers

Install timer units:

```bash
sudo domum-core schedule install-maintenance
```

Enable only the timers you want:

```bash
sudo systemctl enable --now domum-core-checkup.timer
sudo systemctl enable --now domum-core-backups.timer
sudo systemctl enable --now domum-core-recovery-pack.timer
sudo systemctl enable --now domum-core-recovery-email.timer
sudo systemctl enable --now domum-core-updates-check.timer
sudo systemctl enable --now domum-core-updates-apply.timer
sudo systemctl enable --now domum-core-security-patches.timer
sudo systemctl enable --now domum-core-backup-verify.timer
sudo systemctl enable --now domum-core-restore-verify.timer
sudo systemctl enable --now domum-core-weekly-report.timer
sudo systemctl enable --now domum-core-cleanup-report.timer
```

Inspect timing before enabling:

```bash
systemctl cat domum-core-checkup.timer
systemctl cat domum-core-updates-check.timer
systemctl cat domum-core-updates-apply.timer
systemctl list-timers 'domum-core-*'
```

Container auto-updates are controlled app-by-app in `config/domum.conf`; timer
installation alone does not make manual apps update automatically. Keep the
apply timer disabled until you have supervised at least one full check -> status
-> apply-auto --dry-run -> apply-auto cycle on the Pi.

Timer purpose:

| Timer | Purpose |
|---|---|
| `domum-core-checkup.timer` | Regular health report in the journal |
| `domum-core-backups.timer` | Nightly unified service + restic backup |
| `domum-core-backup-verify.timer` | Weekly `restic check` |
| `domum-core-restore-verify.timer` | Monthly partial restore verification |
| `domum-core-weekly-report.timer` | Weekly health report email when enabled |
| `domum-core-recovery-pack.timer` | Refresh encrypted recovery pack |
| `domum-core-recovery-email.timer` | Email latest encrypted recovery pack if enabled |
| `domum-core-updates-check.timer` | Record container update candidates |
| `domum-core-updates-apply.timer` | Apply eligible auto-update candidates after backup and delay gates |
| `domum-core-security-patches.timer` | Apply Debian security patches |
| `domum-core-cleanup-report.timer` | Dry-run Docker image cleanup report |
