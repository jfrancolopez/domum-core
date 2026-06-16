# Setting up backups

Backups use [restic](https://restic.net). All targets ship **disabled** — the
backup scaffolding is fully built, but nothing runs until you fill in real
repositories and passwords and flip `_ENABLED=1`. Until then every backup
command prints a clear notice and exits 0, so timers never error on a fresh
install.

## What gets backed up

`bin/domum-core-backup` backs up (see `BACKUP_PATHS` in
`config/domum-backup.conf`):

- all critical bind mounts (HA, MariaDB data, MQTT, Zigbee2MQTT, Z-Wave,
  ESPHome, Music Assistant, AdGuard, Actual, Traefik config)
- the whole `compose/` tree and `config/`
- `/var/lib/domum-core/service-backups/` — so the Actual/HA/MariaDB artifacts
  ride along
- `/var/lib/domum-core/recovery-pack/` — the encrypted recovery packs
- **named-volume exports** — Node-RED, Uptime-Kuma, Traefik
  letsencrypt are tarred out of their docker volumes into staging first

**Excluded:** DB WAL/SHM files, TTS caches, and other disposable paths
configured in `BACKUP_EXCLUDES`.

## 1. Install restic

```bash
sudo apt-get install -y restic
```

## 2. Choose targets

Edit `/opt/domum-core/config/domum-backup.conf`. Two slots are pre-wired:

- **LOCAL** — a local NAS mount or external disk (`/mnt/backup/domum-core`).
- **HETZNER** — a Hetzner Storage Box over SFTP (port 23, SSH-key auth).

A commented **CLOUD** (Backblaze B2 / S3) slot is included as a template.

## 3. Create restic passwords

Each target needs a password file (used as restic's repo key):

```bash
sudo install -d -m 0700 /etc/domum-core/secrets
openssl rand -base64 32 | sudo tee /etc/domum-core/secrets/restic_password_local >/dev/null
sudo chmod 600 /etc/domum-core/secrets/restic_password_local
```

Repeat for `restic_password_hetzner`. **Save these passwords off-box** — without
them the backups are unrecoverable. (They are also bundled into the encrypted
recovery pack.)

## 4. Hetzner SFTP key (offsite target)

```bash
ssh-keygen -t ed25519 -f /etc/domum-core/secrets/hetzner_storagebox_ed25519 -N ''
# upload the .pub to the Storage Box, then pin the host key:
ssh-keyscan -p 23 uXXXXXX.your-storagebox.de \
  | sudo tee /etc/domum-core/secrets/hetzner_storagebox_known_hosts >/dev/null
```

Set `BACKUP_TARGET_HETZNER_REPOSITORY="sftp:uXXXXXX@uXXXXXX.your-storagebox.de:/./domum-core-restic"`.
See `docs/SETUP-HETZNER-BACKUP.md` for the full Hetzner setup.

## 5. Enable + initialize

```bash
# set BACKUP_TARGET_LOCAL_ENABLED=1 (and/or HETZNER) in domum-backup.conf
sudo domum-core backups init local
sudo domum-core backups init hetzner
```

## 6. Dry run, then for real

```bash
sudo domum-core backups run --dry-run
sudo domum-core backups run
sudo domum-core backups verify
sudo domum-core backups snapshots
```

## 7. Enable the timers

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-backups.timer
sudo systemctl enable --now domum-core-backup-verify.timer
```

## Retention

`RESTIC_KEEP_DAILY/WEEKLY/MONTHLY/YEARLY` in `domum-backup.conf` drive
`restic forget --prune`. Default: 7 daily, 5 weekly, 12 monthly, 3 yearly.

## Restoring

See `docs/DISASTER-RECOVERY.md`. Quick form:

```bash
sudo domum-core-backup --snapshots
sudo domum-core-backup --restore <snapshot-id> /tmp/restore local
```
