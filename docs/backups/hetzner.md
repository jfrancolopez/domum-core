# Hetzner Storage Box backups

This configures the offsite `hetzner` restic target using SFTP on Hetzner
Storage Box port `23` with SSH key authentication.

Run these steps on the production Pi. Do not put Storage Box passwords, restic
passwords, or SSH keys in git.

## 0. Fill these values

Set these variables in the shell you will use for the steps below. Replace the
example user with the Storage Box user or subaccount you actually use.

```bash
HETZNER_USER="uXXXXXX"
HETZNER_HOST="uXXXXXX.your-storagebox.de"
HETZNER_REPO="sftp:${HETZNER_USER}@${HETZNER_HOST}:/./domum-core-restic"
```

The `/./` path form is intentional. It pins restic to
`domum-core-restic` below the Storage Box login root.

## 1. Install local tools

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends restic openssh-client
```

## 2. Create the secrets directory

```bash
sudo install -d -m 0700 -o root -g root /etc/domum-core/secrets
```

## 3. Create the Hetzner restic password

This is the encryption password for the Hetzner restic repository. Save it in
your password manager or other offline recovery notes. Without it, the offsite
backup cannot be restored.

```bash
openssl rand -base64 32 | sudo tee /etc/domum-core/secrets/restic_password_hetzner >/dev/null
sudo chown root:root /etc/domum-core/secrets/restic_password_hetzner
sudo chmod 600 /etc/domum-core/secrets/restic_password_hetzner
```

## 4. Create the Storage Box SSH key

```bash
sudo ssh-keygen -t ed25519 \
  -f /etc/domum-core/secrets/hetzner_storagebox_ed25519 \
  -N '' \
  -C 'domum-core-hetzner-backups'
sudo chown root:root /etc/domum-core/secrets/hetzner_storagebox_ed25519*
sudo chmod 600 /etc/domum-core/secrets/hetzner_storagebox_ed25519
sudo chmod 644 /etc/domum-core/secrets/hetzner_storagebox_ed25519.pub
```

Show the public key:

```bash
sudo sed -n '1p' /etc/domum-core/secrets/hetzner_storagebox_ed25519.pub
```

Copy that one public-key line into Hetzner for the Storage Box user or
subaccount selected in step 0. Use Hetzner Robot / Storage Box access settings,
or the equivalent SSH-key management screen for your account.

## 5. Pin the Storage Box host key

```bash
ssh-keyscan -p 23 "${HETZNER_HOST}" \
  | sudo tee /etc/domum-core/secrets/hetzner_storagebox_known_hosts >/dev/null
sudo chown root:root /etc/domum-core/secrets/hetzner_storagebox_known_hosts
sudo chmod 600 /etc/domum-core/secrets/hetzner_storagebox_known_hosts
sudo ssh-keygen -lf /etc/domum-core/secrets/hetzner_storagebox_known_hosts
```

Compare the printed fingerprint with Hetzner's Storage Box host-key fingerprint
shown in your Hetzner account. Do not disable `StrictHostKeyChecking` to make a
failed connection work.

## 6. Test SFTP login

```bash
printf 'pwd\nbye\n' | sudo sftp \
  -P 23 \
  -i /etc/domum-core/secrets/hetzner_storagebox_ed25519 \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o PasswordAuthentication=no \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile=/etc/domum-core/secrets/hetzner_storagebox_known_hosts \
  "${HETZNER_USER}@${HETZNER_HOST}"
```

Success looks like an SFTP connection that prints the remote working directory
and exits after `bye`.

## 7. Configure the Hetzner target

Print a ready-to-paste config block using the variables from step 0:

```bash
printf '%s\n' \
  'BACKUP_TARGETS="hetzner"' \
  '' \
  'BACKUP_TARGET_HETZNER_ENABLED=1' \
  "BACKUP_TARGET_HETZNER_REPOSITORY=\"${HETZNER_REPO}\"" \
  'BACKUP_TARGET_HETZNER_PASSWORD_FILE="/etc/domum-core/secrets/restic_password_hetzner"' \
  'BACKUP_TARGET_HETZNER_RETENTION="daily"' \
  'BACKUP_TARGET_HETZNER_SFTP_KEY_FILE="/etc/domum-core/secrets/hetzner_storagebox_ed25519"' \
  'BACKUP_TARGET_HETZNER_SFTP_KNOWN_HOSTS_FILE="/etc/domum-core/secrets/hetzner_storagebox_known_hosts"' \
  'BACKUP_TARGET_HETZNER_SFTP_PORT="23"'
```

Open the live backup config and paste that block over the existing Hetzner
section. Keep `local` in `BACKUP_TARGETS` if you also use it; otherwise
`hetzner` alone is fine.

```bash
sudoedit /opt/domum-core/config/domum-backup.conf
```

Validate that the config still parses:

```bash
sudo domum-core configure --validate
```

## 8. Initialize the restic repository

```bash
sudo domum-core backups init hetzner
```

Success looks like `Repository ready` and a metadata file under
`/var/lib/domum-core/backups/hetzner-repo.env`.

If the command says the repository is already initialized, that is fine.

## 9. Create a fresh recovery pack

The recovery pack carries config and secrets needed after a disaster. Creating
one before the first real Hetzner backup makes the pack ride into the offsite
snapshot.

```bash
sudo domum-core recovery-pack create --dry-run
sudo domum-core recovery-pack create
sudo domum-core recovery-pack status
```

If the command asks for an AGE public key, follow [Recovery pack](recovery-pack.md)
and [AGE keypair for the recovery pack](../reference/secrets.md#age-keypair-for-the-recovery-pack),
then rerun this step.

## 10. Run the first backup

```bash
sudo domum-core backups run --dry-run
sudo domum-core backups run
sudo domum-core backups snapshots
sudo domum-core backups verify
sudo domum-core checkup
```

Success criteria:

- `backups run` exits successfully.
- `backups snapshots` shows a snapshot under `-- hetzner --`.
- `backups verify` completes without a restic check error.
- `checkup` reports at least one restic target enabled and a fresh backup.

## 11. Enable scheduled backups

Install the maintenance unit files. This copies unit files only; it does not
enable timers by itself.

```bash
sudo domum-core schedule install-maintenance
```

Review the schedule:

```bash
systemctl cat domum-core-backups.timer
systemctl cat domum-core-backup-verify.timer
systemctl cat domum-core-recovery-pack.timer
```

Enable the backup, weekly restic check, and weekly recovery-pack timers:

```bash
sudo systemctl enable --now domum-core-backups.timer
sudo systemctl enable --now domum-core-backup-verify.timer
sudo systemctl enable --now domum-core-recovery-pack.timer
systemctl list-timers 'domum-core-*'
```

## Daily operations

Use these commands to inspect the setup later:

```bash
sudo domum-core backups snapshots
sudo domum-core backups history
sudo domum-core backups prune --dry-run
sudo domum-core checkup
```

## Troubleshooting

`Permission denied (publickey)` means the public key is missing from Hetzner or
was added to the wrong Storage Box user or subaccount. Recheck step 4.

`Host key verification failed` means the pinned known-hosts file does not match
the server you reached. Recheck the host name and fingerprint in step 5.

`repository not initialized` means the target is reachable but restic has not
created its repository yet. Run:

```bash
sudo domum-core backups init hetzner
```

A stale Hetzner warning in `checkup` means another target may still be fresh,
but the offsite destination needs attention. Inspect the last backup run:

```bash
sudo journalctl -u domum-core-backups.service -n 120 --no-pager
sudo domum-core backups history
```

Do not fix SFTP problems by removing the key file, weakening file permissions,
or disabling host-key checking. Fix the configured user, key, host, or pinned
fingerprint instead.
