# domum-core configure

`sudo domum-core configure` is the interactive configuration wizard. It reads
`config/domum.conf` and `config/domum-backup.conf`, keeps existing comments and unknown
keys, and rewrites only the keys you answer.

## Commands

```bash
sudo domum-core configure
sudo domum-core configure --show
sudo domum-core configure --validate
sudo domum-core configure --backup-current
sudo domum-core configure --write-defaults
```

- `--show` prints effective configuration with secrets redacted.
- `--validate` checks required values and referenced secret files.
- `--backup-current` copies current configs to `/var/lib/domum-core/config-backups/`.
- `--write-defaults` creates missing live configs from their examples without
  overwriting existing files.

The wizard covers:

- Identity
- Services
- Backups
- Recovery
- Updates
- Health Checks
- Timers

Updates are configured app-by-app:

```text
Home Assistant:
  Auto-update? [0]
  Delay days? [14]
MQTT:
  Auto-update? [0]
  Delay days? [7]
Traefik:
  Auto-update? [1]
  Delay days? [1]
```

`--show` redacts password, token, secret, and key-related values.
