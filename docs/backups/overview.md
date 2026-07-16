# Setting up backups

Backups use [restic](https://restic.net). All targets ship **disabled** — the
backup scaffolding is fully built, but nothing runs until you fill in real
repositories and passwords and flip `_ENABLED=1`. Until then every backup
command prints a clear notice and exits 0, so timers never error on a fresh
install.

## What gets backed up

A Hetzner/restic backup is not just the compose YAML files. The default
`BACKUP_PATHS` in `bin/domum-core-backup` includes whole directory trees:

| Offsite restic path | What it protects |
|---|---|
| `/opt/domum-core/compose` | Service bind mounts and compose fragments |
| `/opt/domum-core/config` | Live domum-core config, including backup target metadata |
| `/var/lib/domum-core/service-backups/actual` | Quiesced Actual Budget SQLite archives |
| `/var/lib/domum-core/service-backups/mariadb` | MariaDB SQL dumps, the authoritative database backup |
| `/var/lib/domum-core/service-backups/vaultwarden` | Quiesced Vaultwarden SQLite archives |
| `/var/lib/domum-core/service-backups/volumes` | Docker named-volume exports |
| `/var/lib/domum-core/service-backups/BACKUP-MANIFEST.json` | Per-run backup manifest |
| `/var/lib/domum-core/recovery-pack` | AGE-encrypted recovery packs containing config and small secret files |

Because `/opt/domum-core/compose` is a whole directory tree, the offsite backup
includes the live data directories under it:

| Service | Data included in restic |
|---|---|
| Actual Budget | `/opt/domum-core/compose/productivity/actual-budget/data` |
| Home Assistant | `/opt/domum-core/compose/automation/home-assistant` |
| Home Assistant recorder/history | MariaDB SQL dump under `/var/lib/domum-core/service-backups/mariadb` |
| Vaultwarden | `/opt/domum-core/compose/security/vaultwarden/data` |
| Obsidian Sync | `/opt/domum-core/compose/productivity/obsidian-sync/data` and `etc` |
| MQTT | `/opt/domum-core/compose/automation/mqtt` |
| Zigbee2MQTT | `/opt/domum-core/compose/automation/zigbee2mqtt` |
| Z-Wave JS UI | `/opt/domum-core/compose/automation/zwave-js-ui/store` |
| ESPHome | `/opt/domum-core/compose/automation/esphome` |
| Music Assistant | `/opt/domum-core/compose/automation/music-assistant` |
| AdGuard Home | `/opt/domum-core/compose/networking/adguard` |
| Node-RED | named-volume export `nodered-data.tar.gz` |
| Uptime Kuma | named-volume export `uptime-kuma-data.tar.gz` |
| Traefik certificates | named-volume export `traefik-letsencrypt.tar.gz` |

The rest of the service-backup staging (`/var/lib/domum-core/service-backups/*`)
stays **local-only** by default. Those `.tar.gz` files exist for fast same-host
restores and the update backup gate, but most of them are not sent to restic
because they duplicate the same bytes already captured under `compose/` and are
opaque to restic dedup.

Decision: only Actual Budget and Vaultwarden service archives are promoted into
offsite restic. They are SQLite-backed apps, and `domum-core backups run` pauses
each container for the short tar window before restic runs. Do not add the whole
`service-backups` tree; that would reintroduce the compressed-archive storage
growth that task 21 removed. Obsidian Sync remains raw-bind-mount only until a
small CouchDB-native export is chosen; a hot tar would not be materially safer.

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

## Restore verification

`restic check` verifies repository integrity; restore verification proves that a
small, critical slice can actually be restored and still looks structurally
usable. Run it manually first, then enable the monthly timer if it passes:

```bash
sudo domum-core backups verify-restore
sudo domum-core checkup
sudo systemctl enable --now domum-core-restore-verify.timer
```

The command rotates across enabled backup targets, restores only selected paths
under `/var/lib/domum-core/restore-verify/<timestamp>/`, validates them, records
the result in `/var/lib/domum-core/backups/last-restore-verify`, and removes the
staging directory. Use `--keep-staging` only while debugging a failed check.

It verifies:

- Actual Budget data directory contains non-empty files.
- Latest Actual Budget service archive passes tar/gzip validation.
- Home Assistant `configuration.yaml` and `.storage/core.config_entries` exist.
- The latest MariaDB SQL dump passes `gzip -t` and contains the HA `states`
  table.
- Latest Vaultwarden service archive passes tar/gzip validation.
- Zigbee2MQTT config, and coordinator backup when present in live data, restore.
- Restored staging artifacts match `BACKUP-MANIFEST.json` checksums when the
  snapshot contains a manifest.

It does **not** prove app-level semantic correctness or that a full rebuilt Pi
boots end-to-end. Do the annual [fire drill](fire-drill.md) for that.

**Excluded:** raw MariaDB InnoDB files (`compose/automation/mariadb/data`) are
intentionally excluded because a hot copy is not a reliable restore source. The
SQL dump above is the authoritative MariaDB backup. DB WAL/SHM files, TTS
caches, and other disposable paths in `BACKUP_EXCLUDES` are also excluded.

**Consistency:** MariaDB is protected by a logical `mariadb-dump`, and named
volumes are exported before restic runs. Actual Budget and Vaultwarden are
protected two ways: their raw bind-mounted data is still present under
`compose/`, and their quiesced service archives are included offsite as the
authoritative SQLite restore source. Obsidian Sync/CouchDB is still raw
bind-mount only; the safer future option is a CouchDB-native export, not a hot
tar of the same files.

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

Use the copy-paste runbook in [Hetzner Storage Box backups](hetzner.md). It
covers the restic password, SSH key, Storage Box public-key upload, known-host
pinning, repository initialization, first backup, verification, and timers.

Canonical repository form:

```bash
BACKUP_TARGET_HETZNER_REPOSITORY="sftp:uXXXXXX@uXXXXXX.your-storagebox.de:domum-core-restic"
```

The path is relative on purpose. Hetzner Storage Box port `23` only allows
writes below the login root; absolute paths such as `:/./domum-core-restic`
fail during `restic init`.

## 5. Enable + initialize

```bash
# set BACKUP_TARGET_<NAME>_ENABLED=1 in domum-backup.conf first
sudo domum-core backups init hetzner
sudo domum-core backups init local      # only if LOCAL is enabled too
```

## 6. Dry run, then for real

```bash
sudo domum-core backups run --dry-run
sudo domum-core backups run
sudo domum-core backups verify
sudo domum-core backups verify-restore
sudo domum-core backups snapshots
sudo domum-core checkup
```

## 7. Enable the timers

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-backups.timer
sudo systemctl enable --now domum-core-backup-verify.timer
sudo systemctl enable --now domum-core-restore-verify.timer
sudo systemctl enable --now domum-core-recovery-pack.timer
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
