# Maintenance timers

Install timer units:

```bash
sudo domum-core schedule install-maintenance
```

Enable only the timers you want:

```bash
sudo systemctl enable --now domum-core-checkup.timer
sudo systemctl enable --now domum-core-updates-check.timer
sudo systemctl enable --now domum-core-backups.timer
sudo systemctl enable --now domum-core-recovery-pack.timer
sudo systemctl enable --now domum-core-security-patches.timer
```

Inspect timing before enabling:

```bash
systemctl cat domum-core-checkup.timer
systemctl cat domum-core-updates-check.timer
systemctl list-timers 'domum-core-*'
```

Container auto-updates are controlled app-by-app in `config/domum.conf`; timer
installation alone does not make manual apps update automatically.
