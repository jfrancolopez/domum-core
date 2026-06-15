# domum-core: Production Management Layer (audit, CLI, backups, recovery, updates)

## Context

`domum-core` is a **production** Raspberry Pi 5 home‑automation server (Home Assistant,
MQTT, Zigbee2MQTT, Z‑Wave JS UI, Node‑RED, ESPHome, Music Assistant, AdGuard, Actual
Budget, MariaDB, Traefik, Portainer, etc.). The repo today is **deployment‑focused**: a
small `bin/domum` CLI converges Docker Compose state from `config/domum.conf` toggles, and
`install.sh` bootstraps it. There is **no backup, no health‑check, no recovery, and no
cautious update tooling** — the only documented backup is an rsync cron snippet in
`docs/setup-rpi.md`.

The sibling project `domum-core-media` (`/Users/franco.lopez/Desktop/domum-core-media`) has
a mature operating model we will replicate: a single CLI with `status/checkup/backup/
recovery-pack/updates` commands, restic multi‑target backups, AGE‑encrypted recovery packs,
and systemd timers. This plan ports that model onto `domum-core` **without risking the
running home‑automation stack**.

**Decisions confirmed by the user:**
1. **Consolidate to one CLI named `domum-core`.** Audit and rewrite the existing `bin/domum`,
   folding all current functions (`init/apply/update/status/schedule`) plus all new commands
   into a single `bin/domum-core`. Install as `/usr/local/bin/domum-core`. Keep a thin
   `domum` → `domum-core` symlink/shim for back‑compat.
2. **Restic = scaffold + safe placeholders**, all targets DISABLED by default. Full logic
   ships; nothing runs until the user fills in real repos/passwords and enables.
3. **Timers: install units but leave them disabled.** Provide an installer subcommand; do not
   `enable --now` anything automatically.
4. **Email recovery‑pack delivery: implemented but disabled by default.** Only the AGE‑
   encrypted pack is ever emailed.

**Guiding rules:** audit before change; backup before update; dry‑run before destructive
action; never stop HA/MQTT/Zigbee2MQTT/Node‑RED/Traefik/Actual/AdGuard unless the command is
explicit, documented, and config‑gated; default to no downtime; never delete existing files;
never rotate secrets automatically.

---

## Audit findings (to be written into docs/AUDIT.md)

**Service inventory (12 enabled in `config/domum.conf`):** traefik, home-assistant, mariadb,
go2rtc, mqtt, zigbee2mqtt, zwave-js-ui, nodered, esphome, music-assistant, portainer,
adguard-home, actual-budget. Disabled: frigate, uptime-kuma, jellyfin, tailscale.

**Compose layout:** fragment‑per‑service under `compose/<category>/*.yml`, composed by
`compose_files_for_enabled_services()` in `bin/domum`; `compose/base.yml` defines networks
(`domum-proxy/internal/data`) and named volumes. Compose profiles: `core/night/media/ai`.

**Persistent data (two patterns):**
- **Bind mounts under `/opt/domum-core/compose/...`** (the critical, hard‑to‑recreate state):
  HA `automation/home-assistant/`, MariaDB `automation/mariadb/data/`, MQTT
  `automation/mqtt/{config,data,log}/`, Zigbee2MQTT `automation/zigbee2mqtt/`, Z‑Wave
  `automation/zwave-js-ui/store/`, ESPHome `automation/esphome/`, Music Assistant
  `automation/music-assistant/`, AdGuard `networking/adguard/{work,conf}/`, Actual
  `productivity/actual-budget/data/`, Traefik config `proxy/traefik/`.
- **Named volumes:** `traefik-letsencrypt`, `uptime-kuma-data`, `portainer-data`,
  `nodered-data`, `jellyfin-config`, `jellyfin-cache`. (Node‑RED flows live in a *named
  volume* — easy to miss in backups.)

**Secrets/env handling:** secrets live outside the repo at `/etc/domum-core/secrets/`
(cloudflare_api_token, mariadb/mariadb.env, traefik_dashboard_users, go2rtc/, frigate/,
tailscale_authkey). HA `secrets.yaml` and Zigbee2MQTT `secret.yaml` are bind‑mounted from the
repo tree. `.gitignore` excludes `.env`, `secrets/`, `**/data/`, z2m `secret.yaml`.

**Bugs/inconsistencies found (fix as part of rewrite):**
- **Secrets path drift:** `install.sh:34` and `bin/night-profile.sh:14` reference
  `$DOMUM_DIR/secrets` (i.e. `/opt/domum-core/secrets`), but `bin/domum` and every compose
  file use `/etc/domum-core/secrets`. README mentions both. Standardize on
  `/etc/domum-core/secrets`.
- `repo_update()` does `git reset --hard origin/main` — destroys uncommitted local config
  drift on the Pi. Note as an update risk.

**Gaps (the whole point of this work):**
- **Backup:** none in code (only rsync doc). No restic, no offsite, no verification.
- **Restore:** no documented restore path for HA, Actual, MariaDB, named volumes.
- **Health checks:** none beyond compose healthchecks; no host/temp/disk/restart‑loop checks.
- **Disaster recovery:** no runbook; secrets exist only on the Pi (single point of loss).
- **Updates:** `image: latest` everywhere + `git reset --hard` = uncontrolled updates, no
  backup‑before‑update, no rollback metadata, no history.
- **Per‑service backup for Actual Budget & Home Assistant:** none.

---

## Target on‑disk layout (mirrors domum-core-media)

| Purpose | Path |
|---|---|
| Git repo | `/opt/domum-core` (unchanged) |
| Config | `/opt/domum-core/config/domum.conf` (unchanged; **extend** with new sections) |
| Secrets | `/etc/domum-core/secrets/` (unchanged; add restic passwords, age keypair) |
| Runtime state | `/var/lib/domum-core/` (NEW: backups/, service-backups/, recovery-pack/, update-history/, rollback/) |
| Logs | `/var/log/domum-core/` (NEW) |
| Service backup staging | `/var/lib/domum-core/service-backups/{actual,homeassistant,mariadb}/` (NEW) |

State/log dirs are created (mode 0750) by the CLI; nothing under `/var` is in git.

---

## Deliverables

### 1. Single consolidated CLI — `bin/domum-core` (rewrite of `bin/domum`)

Keep the existing helpers verbatim where they work (`install_docker`, `ensure_dirs`,
`ensure_networks`, `compose_files_for_enabled_services`, `profiles_for_apply`,
`export_env_for_compose`, `compose_cmd`, `init_host`, `apply`, `domum_night_autostop`,
`schedule_install/remove`). Add a `load_cfg` that also sources an optional
`config/domum-backup.conf` (placeholders) so the main `domum.conf` stays clean.

**Command surface (dispatch via `case`, same style as today):**

```
domum-core init | apply | update | status [--counts] | schedule install|remove
domum-core checkup [--json|--quiet]
domum-core doctor
domum-core backups run [--dry-run] | verify | snapshots | prune [--dry-run]
domum-core actual backup [--dry-run] | restore-plan
domum-core homeassistant backup [--dry-run] | restore-plan
domum-core recovery-pack create [--dry-run] [--no-email] | status | inspect
domum-core updates check | apply [--class A|B|C|D] [--dry-run] | history
domum-core cleanup images [--dry-run]
```

Shared infra to add near the top: `log()`/`warn()`/`die()`, `DRY_RUN` flag + `run()` wrapper
(echoes instead of executing when dry‑run), `ensure_state_dirs()`, `service_running()` and
`container_for()` helpers that **resolve real container names from compose** (no hardcoding —
use `compose_cmd ps --format` / `docker inspect`), and a `confirm()` guard for any mutating
op on protected services.

`status --counts`: running/total container counts + per‑category summary (port the media
project's `--counts`).

### 2. Backups — `bin/domum-core-backup` (restic wrapper) + config

Port `domum-core-media/bin/domum-media-backup` structure: `restic_with_env()` subshell
isolation, `restic_for_target()` (types: `repository` for local/rest/sftp/b2), per‑target
helpers reading `BACKUP_TARGET_<NAME>_*` keys.

**New config file `config/domum-backup.conf.example`** (copied to `.conf` by `init`, never
committed) with three targets, **all `_ENABLED=0`**:
- `LOCAL` → `/mnt/backup/domum-core` placeholder (local NAS mount)
- `HETZNER` → `sftp:` / `rest:` Hetzner Storage Box B11 placeholder + SSH key path
- (cloud B2 placeholder commented)

**Backup source set (configurable `BACKUP_PATHS`):** all critical bind mounts listed in the
audit + compose files + `config/` + `/var/lib/domum-core/service-backups/` (so Actual/HA
artifacts ride along) + **rendered exports of named volumes** (Node‑RED, Uptime‑Kuma,
Portainer) created by tar‑from‑volume into the service‑backup staging area. **Excludes:**
Jellyfin cache, Frigate media (`/mnt/domum/frigate`), large disposable data.

`backups run` flow: ensure service‑level backups are fresh (call actual/HA/mariadb backup
funcs) → restic backup to each enabled target → retention `forget` → write heartbeat to
`/var/lib/domum-core/backups/last-success`. `--dry-run` prints the plan and runs `restic
backup --dry-run` where possible. `verify` → `restic check`. `snapshots` → `restic
snapshots`. `prune` → `restic forget --prune` (guarded; `--dry-run` first).

If **no target is enabled**, every backup command prints a clear "no targets configured —
see SETUP-BACKUPS.md" and exits 0 (non‑fatal) so timers don't error on a fresh install.

### 3. Actual Budget per‑service backup (special handling)

- Resolve container from `compose/productivity/actual-budget.yml` (`actual-budget`), data dir
  `compose/productivity/actual-budget/data/` (`ACTUAL_DATA_DIR=/data`).
- **Default = no downtime, filesystem‑level:** `tar` the data dir into
  `/var/lib/domum-core/service-backups/actual/actual-YYYYMMDD-HHMMSS.tar.gz`. Actual uses
  SQLite; add an optional, **config‑gated** (`ACTUAL_QUIESCE=0` default) short `docker pause`
  around the tar for a consistent copy, documented as opt‑in.
- Retain last N (configurable). Included in restic via the staging path.
- `actual restore-plan`: prints exact, **non‑destructive** restore steps (stop container,
  move current data aside, extract chosen archive, start, verify in UI). Never auto‑overwrites.

### 4. Home Assistant per‑service backup (special handling)

- Detect install type: this is the **container** image
  (`ghcr.io/home-assistant/home-assistant:stable`, container `homeassistant`), config bind
  mount `compose/automation/home-assistant/`.
- **Default filesystem‑level:** tar the config dir (excluding `*.db-wal/-shm`, `tts/`,
  `deps/`) → `/var/lib/domum-core/service-backups/homeassistant/ha-YYYYMMDD-HHMMSS.tar.gz`.
  Also **dump the HA MariaDB recorder DB** via `mariadb-dump` inside the `mariadb` container
  (HA history lives in MariaDB, not the config dir) → same staging dir. This doubles as the
  MariaDB backup.
- Try HA's own backup via `ha`/websocket only if trivially available; otherwise skip with a
  note (do not depend on it).
- **Never restart HA.** `homeassistant restore-plan`: documented manual restore.

### 5. Recovery pack (AGE‑encrypted) — port from media project

`recovery-pack create`: stage `config/domum.conf` (sanitized), encrypted copies of
`/etc/domum-core/secrets/*` (small files only), compose files, `git rev-parse HEAD`,
`compose_cmd config` rendered manifest, backup target metadata (repo URLs, **not** passwords
in cleartext), Tailscale/Cloudflare notes, service inventory, last container image digests
(`docker inspect`), Actual + HA restore notes, and a generated `RESTORE.md`. → tar → `age -r`
encrypt → `/var/lib/domum-core/recovery-pack/recovery-pack-<ts>.tar.age`. Writes
`last.env` (PATH/SHA256/SIZE/TS) for checkup age tracking. Optional SMTP email of the `.age`
file, **disabled by default**. `status` reads `last.env`; `inspect` lists archive contents
(metadata only, requires private key to decrypt — documented). `--dry-run` lists what would
be packed without writing.

AGE keypair: `recovery-pack create` warns + instructs if
`/etc/domum-core/secrets/recovery-age.pub` is missing; **never auto‑generates/rotates**.

### 6. Cautious update model — `updates` command

Service classes (config‑declared so user can adjust):
- **A infra:** traefik, adguard-home, uptime-kuma, portainer, tailscale
- **B home‑automation critical:** home-assistant, mariadb, mqtt, zigbee2mqtt, zwave-js-ui,
  nodered, esphome
- **C personal apps:** actual-budget, music-assistant, jellyfin
- **D host OS:** apt packages

`updates check`: for each enabled service, `docker pull --quiet` to a temp tag *or* compare
local vs registry digest (read‑only) and report which images have newer digests; report apt
upgradable count. `updates apply`: conservative — **requires a fresh backup
(`backups run`/service backup) before touching any Class B/stateful service**; refuses
without `--force`; pulls + `up -d` only the selected class; records before/after image
digests to `/var/lib/domum-core/update-history/<ts>.env` (rollback metadata) and appends to a
history log. `updates history`: prints the log. Improves (does not replace) the existing
`update` repo‑pull command, which is kept as `domum-core update` but its `git reset --hard` is
softened to warn on local changes.

### 7. Comprehensive `checkup` (port + extend media project)

Accumulate findings into `CRITICAL/WARNING/HEALTHY/ACTION` arrays; exit non‑zero only on
CRITICAL; support `--json` and `--quiet`. Checks: host uptime, disk usage (`/`,
`/opt`, `/var`), memory pressure, CPU load, **Pi temperature/throttling**
(`vcgencmd measure_temp` / `get_throttled`, gracefully skipped if absent), docker daemon,
compose services up vs expected, restart‑loop detection (`RestartCount`), unhealthy
containers, recent container errors (`docker logs --since`), Tailscale status (if enabled),
AdGuard HTTP, HA HTTP (`:8123`), Actual HTTP (`:5006`), MQTT port `1883`, Zigbee2MQTT
container, **backup freshness** (heartbeat age vs `BACKUP_MAX_AGE_HOURS`), last restic result,
last recovery‑pack date, secrets dir perms (warn if not `0700`/owner‑root), required env/
secret files present, important ports listening, DNS/network sanity, time sync
(`timedatectl`), **automatic OS update timer status**, and an **ACTION** suggesting
`updates check` with the configured per‑image delay (days). `doctor` = `checkup` plus
deeper diagnostics (compose config validity, network existence, disk SMART if available) and
remediation hints.

### 8. systemd timers — `systemd/` dir + `schedule` installer (install, do NOT enable)

Add unit/timer pairs (Type=oneshot, `Nice`/IO‑class like the media project), logging to
`/var/log/domum-core/`:
- `domum-core-checkup.timer` — daily
- `domum-core-actual-backup.timer` — daily
- `domum-core-homeassistant-backup.timer` — daily
- `domum-core-backup.timer` — daily restic (after service backups)
- `domum-core-recovery-pack.timer` — weekly
- `domum-core-backup-verify.timer` — weekly
- `domum-core-cleanup-report.timer` — weekly (dry‑run report only)

Installer subcommand `domum-core schedule install-maintenance` copies units +
`daemon-reload` but prints the explicit `systemctl enable --now ...` commands for the user to
run — it does **not** enable them. Keep existing night‑profile `schedule install/remove`
intact.

### 9. `cleanup images --dry-run`

`docker image prune` preview (dangling + unused), never touches images referenced by enabled
compose services; `--dry-run` (default for safety) lists; explicit run required to delete.

### 10. `install.sh` update

Install `domum-core` to `/usr/local/bin/domum-core`, add `domum` shim, create
`/var/lib/domum-core` + `/var/log/domum-core`, fix the `/etc/domum-core/secrets` path drift,
copy `*.conf.example` → `.conf` if missing. Keep idempotent re‑run behavior.

---

## Files

**Rewrite:** `bin/domum` → `bin/domum-core` (superset; old file removed only after the new one
is in place, or kept as a thin shim — no functionality lost). `install.sh`,
`bin/night-profile.sh` (path fix only).

**New scripts:** `bin/domum-core-backup`.

**New config:** `config/domum-backup.conf.example`; extend `config/domum.conf` with
update‑class, backup, recovery, checkup, and auto‑OS‑update settings (additive, with safe
defaults).

**New systemd:** `systemd/domum-core-*.{service,timer}` (7 pairs).

**New/updated docs:** `docs/AUDIT.md`, `docs/CHECKUP.md`, `docs/SETUP-BACKUPS.md`,
`docs/DISASTER-RECOVERY.md`, `docs/SECRETS.md`, `docs/CLI-CHEATSHEET.md`,
`docs/ACTUAL-BUDGET-BACKUP.md`, `docs/HOME-ASSISTANT-BACKUP.md`, `docs/UPDATES.md`. Update
`README.md` to point at `domum-core` and the new docs.

**CI:** `.github/workflows/validate.yml` already runs shellcheck — ensure new scripts pass.

---

## Disaster-recovery runbook (docs/DISASTER-RECOVERY.md)

Scenario: Pi 5 dies. Steps: install OS → install Docker → clone repo → install domum-core →
restore secrets from AGE recovery pack (`age -d`) → configure restic creds → `restic restore`
service data → restore Actual (restore-plan) → restore HA config + MariaDB dump → bring up in
safe order (network/DNS → MariaDB → MQTT → Zigbee2MQTT/Z‑Wave → Home Assistant → Actual →
rest) via targeted `compose up` → validate with `domum-core checkup` → abort/rollback path.
**RPO:** Actual ≤24h, HA ≤24h (daily timers). **RTO:** same‑day if hardware available. Covers
rebuild on new Pi 5, temporary Linux box, or another Docker host (note USB device path
differences for Zigbee/Z‑Wave dongles).

---

## Verification (safe to run; mostly read-only / dry-run)

Run locally during dev (macOS) where possible, and document the on‑Pi suite:

```bash
# Lint
shellcheck bin/domum-core bin/domum-core-backup bin/night-profile.sh install.sh

# On the Pi (read-only / dry-run — must not mutate running services):
sudo domum-core status --counts
sudo domum-core checkup
sudo domum-core checkup --json
sudo domum-core backups run --dry-run
sudo domum-core actual backup --dry-run
sudo domum-core homeassistant backup --dry-run
sudo domum-core recovery-pack create --dry-run
sudo domum-core updates check
sudo domum-core cleanup images --dry-run
```

Acceptance: shellcheck clean; every command above runs without stopping/restarting any
container; checkup returns 0 on a healthy host and clearly flags missing backups; all backup/
update/cleanup commands honor `--dry-run` and never act when targets are unconfigured;
existing `domum apply`/night‑profile behavior is unchanged.

---

## What this protects vs. leaves open (to restate in final summary)

- **Protected after setup:** HA config + recorder DB, Actual data, MariaDB, MQTT, Zigbee2MQTT,
  Z‑Wave, Node‑RED (named volume exported), ESPHome, AdGuard, Uptime‑Kuma, Portainer, compose
  files, sanitized config, encrypted secrets — via restic + recovery pack.
- **Still NOT protected until the user acts:** real restic repos/passwords must be filled in
  and targets enabled; AGE keypair must be generated; timers must be enabled; offsite/Hetzner
  + email need credentials. Frigate media and Jellyfin libraries are intentionally excluded.

## Manual steps the user must complete (post-merge, on the Pi)

1. `git pull` in `/opt/domum-core`, re‑run `install.sh` (or `domum-core init`).
2. Generate AGE keypair → `/etc/domum-core/secrets/recovery-age.{key,pub}` (key offline).
3. Fill `config/domum-backup.conf` with real LOCAL/Hetzner repos + create restic password
   files; `restic init` each repo; set `_ENABLED=1`.
4. Run the dry‑run suite above, then a real `backups run` + `backups verify`.
5. Enable chosen timers with the printed `systemctl enable --now` commands.
6. (Optional) configure SMTP for recovery‑pack email.
