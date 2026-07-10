# domum-core CLI cheatsheet

`domum-core` is the consolidated CLI. `domum` is a back-compat shim that execs
`domum-core`. Install path: `/usr/local/bin/domum-core` — a symlink into
`/opt/domum-core/bin/`, so `domum-core update` updates the CLI itself.

All commands run as root (`sudo`).

## Deployment

| Command | What it does |
|---|---|
| `domum-core init` | Install Docker, create dirs, copy `*.conf.example` → `.conf` |
| `domum-core apply` | Converge compose state from `config/domum.conf` toggles |
| `domum-core update` | `git pull` (warns + confirms on local drift); refreshes installed systemd units if they drifted |
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
| `domum-core recovery-pack send-latest [--dry-run]` | Email the latest encrypted pack |
| `domum-core updates check` | Check enabled service images and record candidates |
| `domum-core updates status` | Show candidate digest, first seen, delay, readiness, auto-update, backup gate |
| `domum-core updates apply <app> [--dry-run] [--force]` | Manually apply one recorded app candidate |
| `domum-core updates apply-auto [--dry-run] [--force]` | Apply only ready apps with `<APP>_AUTO_UPDATE=1` |
| `domum-core updates history` | Update log |
| `domum-core os-updates check` | Show pending OS security/general updates |
| `domum-core os-updates security-apply [--dry-run]` | Apply security patches only; never reboot |

## Maintenance

| Command | What it does |
|---|---|
| `domum-core cleanup images [--dry-run]` | Prune dangling, unused images (dry-run default) |
| `domum-core schedule install` | Night-profile timers |
| `domum-core schedule install-maintenance` | Install (not enable) maintenance timers |

## Per-app updates

Update behavior is configured app-by-app in `config/domum.conf`:

```bash
HOMEASSISTANT_AUTO_UPDATE=0
HOMEASSISTANT_UPDATE_DELAY_DAYS=14
```

Class names may appear as documentation labels, but they do not control update
behavior. Stateful apps require fresh backups before update unless `--force` is
used.

## Safe read-only / dry-run suite

```bash
sudo domum-core status --counts
sudo domum-core checkup
sudo domum-core backups run --dry-run
sudo domum-core actual backup --dry-run
sudo domum-core homeassistant backup --dry-run
sudo domum-core recovery-pack create --dry-run
sudo domum-core updates check
sudo domum-core updates status
sudo domum-core updates apply-auto --dry-run
sudo domum-core updates apply homeassistant --dry-run
sudo domum-core os-updates check
sudo domum-core cleanup images --dry-run
```
