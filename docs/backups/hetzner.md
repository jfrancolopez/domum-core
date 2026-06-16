# Hetzner Storage Box Backups

Hetzner backups use restic over SFTP with SSH key authentication.

Example repository:

```bash
BACKUP_TARGET_HETZNER_ENABLED=1
BACKUP_TARGET_HETZNER_REPOSITORY="sftp:uXXXXXX@uXXXXXX.your-storagebox.de:/./domum-core-restic"
BACKUP_TARGET_HETZNER_PASSWORD_FILE="/etc/domum-core/secrets/restic_password_hetzner"
BACKUP_TARGET_HETZNER_SFTP_KEY_FILE="/etc/domum-core/secrets/hetzner_storagebox_ed25519"
BACKUP_TARGET_HETZNER_SFTP_KNOWN_HOSTS_FILE="/etc/domum-core/secrets/hetzner_storagebox_known_hosts"
BACKUP_TARGET_HETZNER_SFTP_PORT="23"
```

Secret files should be root-owned and `0600`.

```bash
sudo domum-core backups init hetzner
sudo domum-core backups run
sudo domum-core backups snapshots
sudo domum-core backups verify
sudo domum-core backups prune --dry-run
```

The `/./` path form pins the Storage Box path to the intended directory. Keep the restic
password outside the repo and store the SSH private key under `/etc/domum-core/secrets`.
