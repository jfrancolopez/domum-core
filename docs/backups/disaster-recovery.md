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

**The hard floor:** exactly two things must survive off-Pi — the AGE private
key and (as a fallback if no pack copy is at hand) one restic password. Both
fit in a password-manager entry plus one printed copy; everything else is
recoverable from the backups themselves.

## Steps

### 1. Base OS + Docker

Flash **Debian 13 Lite (arm64)** to the NVMe drive (production boots natively
from NVMe — see [install](../getting-started/install.md) for imaging and
EEPROM boot-order steps), boot, set hostname/network, then:

```bash
curl -fsSL https://raw.githubusercontent.com/jfrancolopez/domum-core/main/install.sh | sudo bash
```

This clones the repo to `/opt/domum-core`, installs the `domum-core` commands,
and creates `/etc/domum-core/secrets`, `/var/lib/domum-core`, and
`/var/log/domum-core`.

Then converge the mechanical host state before restoring data:

```bash
sudo domum-core init
```

`init` installs Docker if missing, installs the standard backup/recovery utility
packages, configures bounded Docker logs when `/etc/docker/daemon.json` is
absent, and prints the remaining operator checklist. It does not run `apply`.

Order matters: install.sh refuses to overwrite a non-git `/opt/domum-core`,
so restore data only *after* the installer has run.

### 2. Run the guided restore

Copy the recovery pack and your offline AGE key to the new Pi, then:

```bash
sudo domum-core restore --pack recovery-pack-YYYYMMDD-HHMMSS.tar.age --key recovery-age.key
```

The wizard walks the rest of this runbook for you: installs secrets + config
from the pack, lists snapshots per reachable target, restores to staging and
rsyncs into place (every overwritten file keeps a `.pre-restore-*` sibling —
nothing is deleted), re-imports named volumes, brings services up in safe
order, offers to load the newest MariaDB dump, and offers to re-enable the
systemd timers recorded in the backup manifest. Each step prints what it will
do and asks for confirmation.

No recovery pack at hand, but a reachable restic repo and its password?

```bash
sudo domum-core restore --manual   # pulls config + the pack from the repo, then pivots to the pack
```

Steps 3–7 below are the **manual appendix** — the same procedure by hand, for
when the wizard is unavailable or you want to verify what it does.

### 3. Manual: decrypt the recovery pack

On a trusted machine (or the new Pi once you've copied the key securely):

```bash
age -d -i recovery-age.key recovery-pack-YYYYMMDD-HHMMSS.tar.age | tar -xzf -
cat RESTORE.md          # contents + checksums in MANIFEST.txt
```

### 4. Manual: restore secrets + config

```bash
sudo cp -a secrets/.   /etc/domum-core/secrets/
sudo chmod -R 600 /etc/domum-core/secrets/*
sudo chown -R root:root /etc/domum-core/secrets
sudo cp config/domum.conf        /opt/domum-core/config/
sudo cp config/domum-backup.conf /opt/domum-core/config/
```

### 5. Manual: restore service data from restic

restic recreates the **original absolute paths under the target directory**,
so never restore straight onto `/opt/domum-core` (you would get
`/opt/domum-core/opt/domum-core/...`). Restore to a staging directory first
(`/var/tmp` is disk-backed; `/tmp` is RAM and too small for this):

```bash
sudo apt-get install -y restic
sudo domum-core-backup --snapshots
sudo domum-core-backup --restore latest /var/tmp/domum-restore local   # or hetzner
```

The staging tree now holds `opt/domum-core/...` (compose bind mounts, config)
and `var/lib/domum-core/...` (service backups, volume tarballs, recovery
packs). Move it into place, then clean up:

```bash
sudo rsync -aHAX /var/tmp/domum-restore/opt/domum-core/ /opt/domum-core/
sudo rsync -aHAX /var/tmp/domum-restore/var/lib/domum-core/ /var/lib/domum-core/
sudo rm -rf /var/tmp/domum-restore
```

Re-import named volumes:

```bash
for v in nodered-data uptime-kuma-data traefik-letsencrypt; do
  docker volume create "$v"
  docker run --rm -v "$v":/to -v /var/lib/domum-core/service-backups/volumes:/from \
    alpine sh -c "cd /to && tar -xzf /from/$v.tar.gz"
done
```

### 6. Manual: confirm Actual + Home Assistant data

The restic restore in step 5 already restored the offsite copies of:

- Actual Budget data:
  `/opt/domum-core/compose/productivity/actual-budget/data`
- Home Assistant config:
  `/opt/domum-core/compose/automation/home-assistant`
- Home Assistant recorder/history:
  `/var/lib/domum-core/service-backups/mariadb/mariadb-all-*.sql.gz`

Do not expect the Actual or Home Assistant `.tar.gz` service archives to exist
after an offsite-only restore. Those archives are local staging by default.
Use `sudo domum-core actual restore-plan` or
`sudo domum-core homeassistant restore-plan` only when those local archives are
present and you intentionally want to restore from them.

The SQL dump is loaded in step 7 after MariaDB starts and before Home Assistant
is converged.

### 7. Manual: bring services up in safe order

```bash
cd /opt/domum-core
# network / DNS first
sudo docker compose -f compose/base.yml -f compose/networking/adguard-home.yml up -d
# database
sudo docker compose -f compose/base.yml -f compose/automation/mariadb.yml up -d
# load Home Assistant recorder/history before Home Assistant starts
gunzip -c /var/lib/domum-core/service-backups/mariadb/mariadb-all-YYYYMMDD-HHMMSS.sql.gz | \
  sudo docker exec -i $(sudo docker ps -qf name=mariadb) \
  sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"'
# messaging + radios
sudo docker compose -f compose/base.yml -f compose/automation/mqtt.yml up -d
sudo docker compose -f compose/base.yml -f compose/automation/zigbee2mqtt.yml \
  -f compose/automation/zwave-js-ui.yml up -d
# then the rest in one shot
sudo domum-core apply
```

> **USB radios:** `/dev/serial/by-id/...` paths follow the **dongle** (they
> are derived from its USB vendor/product/serial), not the Pi or the port —
> the same dongles keep the same paths on a new Pi. Only edit the z2m/zwave
> compose fragments if you replaced a radio itself.

### 8. Validate

```bash
sudo domum-core checkup
```

> **Tailscale (expected, by design):** Tailscale node keys are intentionally not
> backed up. They are re-issuable, so the omission is designed loss, not a
> hole. If `ENABLE_TAILSCALE=1`, `sudo domum-core init` installs and enables the
> host `tailscaled` service. Re-authenticate after rebuild with
> `sudo tailscale up --accept-dns=false --ssh=false` or with an ephemeral auth
> key. Keep `accept-dns=false` so LAN HTTPS and certificate renewal do not
> depend on Tailscale DNS. Keep `ssh=false` unless Tailscale SSH is intentionally
> enabled in `config/domum.conf`.

### Abort / rollback

If a service misbehaves after restore, its restore-plan moved the old data
aside (`*.bak-<timestamp>`). Stop the service, restore the `.bak` dir, and start
again. Nothing in the restore path overwrites data in place.

## Rebuild targets

This runbook works for: a new Pi 5, a temporary Linux box, or any other Docker
host. The only host-specific details are USB radio device paths and any
hardware-accelerated transcoding (not used by the core stack).

For *planned* drive swaps or moving the NVMe to a new Pi (old drive healthy),
the [storage replacement runbook](../operations/storage-replacement.md) is
faster — but rebuild via this runbook remains the recovery path.
