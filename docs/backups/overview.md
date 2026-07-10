# Setting up backups

Backups use [restic](https://restic.net). All targets ship **disabled** — the
backup scaffolding is fully built, but nothing runs until you fill in real
repositories and passwords and flip `_ENABLED=1`. Until then every backup
command prints a clear notice and exits 0, so timers never error on a fresh
install.

## What gets backed up

`bin/domum-core-backup` backs up (see `BACKUP_PATHS` in
`config/domum-backup.conf`), storing each byte once in restic's
dedup-friendly raw form:

- the whole `compose/` tree (contains every service bind mount: HA, MQTT,
  Zigbee2MQTT, Z-Wave, ESPHome, Music Assistant, AdGuard, Actual,
  Vaultwarden, Traefik config) and `config/`
- `/var/lib/domum-core/service-backups/mariadb/` — the `mariadb-dump` SQL
  artifacts, the authoritative MariaDB backup
- `/var/lib/domum-core/service-backups/volumes/` — **named-volume exports**
  (Node-RED, Uptime-Kuma, Traefik letsencrypt), the only capture of those
  docker volumes
- `/var/lib/domum-core/recovery-pack/` — the encrypted recovery packs

The rest of the service-backup staging (`/var/lib/domum-core/service-backups/`)
stays **local-only**: it exists for fast same-host restores and the update
backup gate, and its gzipped tars are opaque to restic dedup.

## The backup manifest

Every `backups run` writes
`/var/lib/domum-core/service-backups/BACKUP-MANIFEST.json` (schema v1,
additive changes only), which rides inside each restic snapshot and into the
recovery pack's `meta/`. It records what was backed up and from what software
state: git commit, OS/kernel/docker/restic versions, enabled services with
image digests, per-service backup flags, **enabled systemd timers** (host
state a rebuild must recreate), configured targets, and each current staging
artifact's size + sha256 for restore-time integrity checks. Read it from a
snapshot without any domum tooling:

```bash
restic dump latest /var/lib/domum-core/service-backups/BACKUP-MANIFEST.json | jq .
```

Snapshots older than the manifest simply don't have one — consumers treat
that as informational, never an error.

**Excluded:** raw MariaDB InnoDB files (`compose/automation/mariadb/data` —
a hot copy is not a reliable restore source; the SQL dump above is), DB
WAL/SHM files, TTS caches, and other disposable paths in `BACKUP_EXCLUDES`.

**Consistency:** services with live SQLite databases (Actual Budget,
Vaultwarden) are quiesced with `docker pause` for the few seconds their tar
takes during the nightly service backup — a barely-noticeable pause at 02:30
in exchange for copies that cannot be torn mid-write. Opt out with
`ACTUAL_QUIESCE=0` in the overlay for Actual.

**Failure isolation:** every enabled target is attempted every run; a failed
target is reported (run exits non-zero, `checkup` warns which destination is
stale via `last-success-<target>` files) but never cancels the others.

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
See `docs/backups/hetzner.md` for the full Hetzner setup.

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

See `docs/backups/disaster-recovery.md`. Quick form:

```bash
sudo domum-core-backup --snapshots
sudo domum-core-backup --restore <snapshot-id> /var/tmp/domum-restore local
```

(restic recreates the original absolute paths under the target directory —
see the disaster-recovery runbook for moving the tree into place. `/var/tmp`
is disk-backed; `/tmp` is RAM-backed and too small.)
