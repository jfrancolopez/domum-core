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
- `--write-defaults` creates `config/domum-backup.conf` from the example when missing.

The wizard covers identity, service toggles, backup freshness, recovery email, update
classes, security patches, and maintenance settings. It does not print password contents.
