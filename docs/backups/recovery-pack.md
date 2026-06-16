# Recovery pack

The recovery pack stores host identity and rebuild metadata in an AGE-encrypted
archive. It is not a replacement for restic service/data backups.

Create a pack:

```bash
sudo domum-core recovery-pack create
```

Dry run:

```bash
sudo domum-core recovery-pack create --dry-run
```

Status:

```bash
sudo domum-core recovery-pack status
```

Email delivery is optional and disabled by default. See
[Gmail recovery email](gmail-recovery.md).
