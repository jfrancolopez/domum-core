# Disaster recovery runbook

Scenario: the Raspberry Pi 5 dies. This rebuilds the full home-automation stack
on new hardware.

**RPO** (max data loss): Actual ≤24h, Home Assistant ≤24h (daily timers).
**RTO** (time to restore): same-day if replacement hardware is available.

## Prerequisites you must have off the Pi

1. The **AGE private key** (`recovery-age.key`) — kept offline, never on the Pi.
2. The latest **encrypted recovery pack** (`recovery-pack-*.tar.age`) — it's in
   the restic backup and may also have been emailed.
3. The **restic repository passwords** (also bundled in the recovery pack).

## Steps

### 1. Base OS + Docker

Flash Raspberry Pi OS (64-bit), boot, set hostname/network, then:

```bash
curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash
```

This installs Docker, clones the repo to `/opt/domum-core`, installs
`domum-core`, and creates `/etc/domum-core/secrets`, `/var/lib/domum-core`,
`/var/log/domum-core`.

### 2. Decrypt the recovery pack

On a trusted machine (or the new Pi once you've copied the key securely):

```bash
age -d -i recovery-age.key recovery-pack-YYYYMMDD-HHMMSS.tar.age | tar -xzf -
cat RESTORE.md          # contents + checksums in MANIFEST.txt
```

### 3. Restore secrets + config

```bash
sudo cp -a secrets/.   /etc/domum-core/secrets/
sudo chmod -R 600 /etc/domum-core/secrets/*
sudo chown -R root:root /etc/domum-core/secrets
sudo cp config/domum.conf        /opt/domum-core/config/
sudo cp config/domum-backup.conf /opt/domum-core/config/
```

### 4. Restore service data from restic

```bash
sudo apt-get install -y restic
sudo domum-core-backup --snapshots
sudo domum-core-backup --restore latest /opt/domum-core local   # or hetzner
```

restic restores the bind mounts under `compose/...`, the named-volume tarballs
under `/var/lib/domum-core/service-backups/volumes/`, and the service backup
staging dirs. Re-import named volumes:

```bash
for v in nodered-data uptime-kuma-data traefik-letsencrypt; do
  docker volume create "$v"
  docker run --rm -v "$v":/to -v /var/lib/domum-core/service-backups/volumes:/from \
    alpine sh -c "cd /to && tar -xzf /from/$v.tar.gz"
done
```

### 5. Restore Actual + Home Assistant

Follow the printed plans (non-destructive):

```bash
sudo domum-core actual restore-plan
sudo domum-core homeassistant restore-plan
```

The HA recorder history is in the MariaDB dump
(`/var/lib/domum-core/service-backups/mariadb/mariadb-all-*.sql.gz`).

### 6. Bring services up in safe order

```bash
cd /opt/domum-core
# network / DNS first
sudo docker compose -f compose/base.yml -f compose/networking/adguard-home.yml up -d
# database
sudo docker compose -f compose/base.yml -f compose/automation/mariadb.yml up -d
# messaging + radios
sudo docker compose -f compose/base.yml -f compose/automation/mqtt.yml up -d
sudo docker compose -f compose/base.yml -f compose/automation/zigbee2mqtt.yml \
  -f compose/automation/zwave-js-ui.yml up -d
# then the rest in one shot
sudo domum-core apply
```

> **USB radios:** Zigbee/Z-Wave dongle device paths (`/dev/serial/by-id/...`)
> differ on new hardware. Check the z2m and zwave compose fragments and update
> the device path before bringing those services up.

### 7. Validate

```bash
sudo domum-core checkup
```

### Abort / rollback

If a service misbehaves after restore, its restore-plan moved the old data
aside (`*.bak-<timestamp>`). Stop the service, restore the `.bak` dir, and start
again. Nothing in the restore path overwrites data in place.

## Rebuild targets

This runbook works for: a new Pi 5, a temporary Linux box, or any other Docker
host. The only host-specific details are USB radio device paths and any
hardware-accelerated transcoding (not used by the core stack).
