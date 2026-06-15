# domum-core CLI cheatsheet

`domum-core` is the consolidated CLI. `domum` is a back-compat shim that execs
`domum-core`. Install path: `/usr/local/bin/domum-core`.

All commands run as root (`sudo`).

## Deployment

| Command | What it does |
|---|---|
| `domum-core init` | Install Docker, create dirs, copy `*.conf.example` → `.conf` |
| `domum-core apply` | Converge compose state from `config/domum.conf` toggles |
| `domum-core update` | `git pull` (warns + confirms on local drift) |
| `domum-core status [--counts]` | `compose ps`, storage, backup heartbeat; `--counts` adds per-category running/total |

## Health

| Command | What it does |
|---|---|
| `domum-core checkup` | CRITICAL/WARNING/HEALTHY/ACTION report; exits non-zero only on CRITICAL |
| `domum-core checkup --json` | Same, machine-readable |
| `domum-core checkup --quiet` | Print only critical lines |
| `domum-core doctor` | checkup + compose validity, container map, SMART, binaries |

## Backups

| Command | What it does |
|---|---|
| `domum-core backups run [--dry-run]` | Refresh service backups, then restic to every enabled target |
| `domum-core backups verify` | `restic check` on each target |
| `domum-core backups snapshots` | Latest snapshots per target |
| `domum-core backups prune [--dry-run]` | `restic forget --prune` (retention) |
| `domum-core backups init <target>` | Initialize a restic repository |
| `domum-core actual backup [--dry-run]` | Filesystem-level Actual Budget backup |
| `domum-core actual restore-plan` | Print non-destructive restore steps |
| `domum-core homeassistant backup [--dry-run]` | Tar HA config + dump MariaDB recorder |
| `domum-core homeassistant restore-plan` | Print manual restore steps |

## Recovery & updates

| Command | What it does |
|---|---|
| `domum-core recovery-pack create [--dry-run] [--no-email]` | Build AGE-encrypted DR pack |
| `domum-core recovery-pack status` | Age/size/sha of the last pack |
| `domum-core recovery-pack inspect` | How to list the pack's contents |
| `domum-core updates check` | Report images with newer digests + apt count (read-only) |
| `domum-core updates apply --class A\|B\|C\|D [--dry-run]` | Update one class (B/C need a fresh backup) |
| `domum-core updates history` | Update log |

## Maintenance

| Command | What it does |
|---|---|
| `domum-core cleanup images [--dry-run]` | Prune dangling, unused images (dry-run default) |
| `domum-core schedule install` | Night-profile timers |
| `domum-core schedule install-maintenance` | Install (not enable) the 7 maintenance timers |

## Update classes

- **A infra:** traefik, adguard-home, uptime-kuma, portainer, tailscale
- **B HA-critical:** home-assistant, mariadb, mqtt, zigbee2mqtt, zwave-js-ui, nodered, esphome
- **C personal:** actual-budget, music-assistant, jellyfin
- **D host OS:** apt packages

Class B/C are stateful — `updates apply` refuses without a backup newer than
`BACKUP_MAX_AGE_HOURS` (default 48h) unless you pass `--force`.

## Safe read-only / dry-run suite

```bash
sudo domum-core status --counts
sudo domum-core checkup
sudo domum-core backups run --dry-run
sudo domum-core actual backup --dry-run
sudo domum-core homeassistant backup --dry-run
sudo domum-core recovery-pack create --dry-run
sudo domum-core updates check
sudo domum-core cleanup images --dry-run
```
