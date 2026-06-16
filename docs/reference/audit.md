# domum-core audit

This audit tracks the modernization and production-hardening work.

## Exists today

- `bin/domum-core` owns deployment, apply/status, checkup/doctor, Home Assistant
  audit, unified service backups, AGE recovery packs, per-app updates, delayed
  update candidates, OS security patch commands, cleanup, and timer install.
- `bin/domum-core-backup` is the restic multi-target wrapper with local and
  Hetzner SFTP support.
- Service metadata is centralized in `service_catalog()` with logical name,
  enable flag, category, docs/UI label, backup flag, compose file, and probe.
- Backups run through `domum-core backups run`, which creates service-level
  artifacts first and then invokes restic.
- Recovery pack email is encrypt-first and supports Gmail aliases through
  `ENABLE_RECOVERY_EMAIL`, `RECOVERY_EMAIL_TO/FROM`, and
  `GMAIL_APP_PASSWORD_FILE`.
- Maintenance timers install disabled by default through
  `domum-core schedule install-maintenance`.

## Removed intentionally

`go2rtc`, `frigate`, `jellyfin`, and `portainer` were removed from this repo.
Historical containers and volumes are not deleted automatically. See
`docs/reference/removed-services.md`.

## Fixed

- Hardened numeric parsing with `to_int` and `count_matches`, including the
  `grep -c` zero-match `0\n0` arithmetic failure.
- Removed non-mission compose files and service references.
- Reworked backups around `BACKUP_<SERVICE>` flags.
- Added read-only `homeassistant audit`.
- Added `configure`, Vaultwarden, Obsidian CouchDB LiveSync, OS security patch
  commands, delayed update candidates, and recovery email commands.
- Hardened `install.sh` so it no longer hard-resets existing installs or runs
  `init && apply` automatically.

## Still operator-dependent

- Hetzner, Gmail, restic, and AGE secrets must be supplied by the operator.
- Docker compose rendering and Pi-side health checks require the actual host.
- Optional services require DNS records before use.
