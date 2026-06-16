# Health checkup

`domum-core checkup` runs a broad, read-only health sweep and sorts findings
into four buckets. It exits **non-zero only on CRITICAL**, so it's safe in
timers and monitoring.

```bash
sudo domum-core checkup            # human-readable
sudo domum-core checkup --json     # machine-readable {critical,warnings,healthy,suggested_actions}
sudo domum-core checkup --quiet    # print only critical lines
sudo domum-core doctor             # checkup + deeper diagnostics
```

## What it checks

- **Host:** disk usage (`/`, `/opt`, `/var/lib/domum-core`), memory pressure,
  time sync (`timedatectl`), pending reboot, apt security/general updates.
- **Pi:** temperature and throttling flags via `vcgencmd` (skipped gracefully
  off-Pi).
- **Docker:** daemon responsive, required networks exist, each enabled service
  running vs expected, restart-loop detection (`RestartCount`), unhealthy
  containers, dangling images.
- **Reachability:** MQTT `1883`, optional configured Home Assistant/Actual
  health URLs, Tailscale status (if enabled).
- **Backups:** at least one restic target enabled, backup freshness vs
  `BACKUP_MAX_AGE_HOURS`, presence of Actual/HA/MariaDB service backups.
- **Recovery:** recovery-pack age vs `RECOVERY_PACK_REMINDER_DAYS`, `age`
  binary present.
- **Secrets:** `/etc/domum-core/secrets` is `0700` / owner root.

## doctor extras

`doctor` adds: compose config validity, the enabled-service→container map, disk
SMART health (if `smartmontools` is installed), and a required-binary check
(`docker`, `restic`, `age`, `curl`, `jq`).

## Schedule

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-checkup.timer   # daily 07:30
```

Logs to `/var/log/domum-core/`.

## Optional HTTP checks

Home Assistant and Actual Budget are usually routed through Traefik and may not
publish localhost ports. The checkup command does not warn on `127.0.0.1:8123`
or `127.0.0.1:5006` by default.

Enable explicit URL checks only when you want them:

```bash
HEALTHCHECK_HOMEASSISTANT_HTTP=1
HOMEASSISTANT_HEALTH_URL="https://ha.example.com/"
HEALTHCHECK_ACTUAL_HTTP=1
ACTUAL_HEALTH_URL="https://actual.example.com/"
```
