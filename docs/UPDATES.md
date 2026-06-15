# Cautious updates

The `updates` command replaces uncontrolled `image: latest` pulls + `git reset
--hard` with a class-based, backup-gated model. Nothing updates automatically —
you choose when, and which class.

## Classes

| Class | Services | Policy |
|---|---|---|
| **A** infra | traefik, adguard-home, uptime-kuma, portainer, tailscale | low-risk |
| **B** HA-critical | home-assistant, mariadb, mqtt, zigbee2mqtt, zwave-js-ui, nodered, esphome | **backup gate** |
| **C** personal | actual-budget, music-assistant, jellyfin | **backup gate** |
| **D** host OS | apt packages | `apt upgrade` |

Classes are config-declared (`UPDATE_CLASS_A/B/C` in `config/domum.conf` or
`domum-backup.conf`) so you can move a service between classes.

## Check (read-only)

```bash
sudo domum-core updates check
```

For each enabled service it does a read-only `docker pull` and compares the
local vs registry image digest, reporting which have a newer image. It also
reports the apt upgradable count.

## Apply

```bash
sudo domum-core updates apply --class A
sudo domum-core updates apply --class B --dry-run
sudo domum-core updates apply --class D
```

- **Class B/C are stateful.** `apply` refuses unless a backup (restic heartbeat
  or a service-level backup) is newer than `BACKUP_MAX_AGE_HOURS` (default 48h).
  Override with `--force` (logged).
- Before/after image digests and the outcome are recorded to
  `/var/lib/domum-core/update-history/<service>-<ts>.env` and appended to
  `history.log` for rollback reference.
- `--dry-run` prints the pull/up commands without running them.

## History

```bash
sudo domum-core updates history
```

## Repo updates

`domum-core update` still pulls the git repo, but its `git reset --hard
origin/main` now **warns and asks for confirmation** when there is local
uncommitted drift — it no longer silently discards local config changes.

## Weekly report timer (optional)

```bash
sudo domum-core schedule install-maintenance
sudo systemctl enable --now domum-core-cleanup-report.timer  # dry-run image report
```
