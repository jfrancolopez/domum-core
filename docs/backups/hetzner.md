# Hetzner Storage Box backups

This configures the offsite `hetzner` restic target using SFTP on Hetzner
Storage Box port `23` with SSH key authentication.

Run these steps on the production Pi. Do not put Storage Box passwords, restic
passwords, or SSH keys in git.

There are two kinds of values in this guide:

| Value | Permanent location |
|---|---|
| Hetzner Storage Box user | inside `BACKUP_TARGET_HETZNER_REPOSITORY` in `/opt/domum-core/config/domum-backup.conf` |
| Hetzner Storage Box host | inside `BACKUP_TARGET_HETZNER_REPOSITORY` in `/opt/domum-core/config/domum-backup.conf` |
| restic repository password | `/etc/domum-core/secrets/restic_password_hetzner` |
| SSH private key for unattended SFTP | `/etc/domum-core/secrets/hetzner_storagebox_ed25519` |
| SSH public key | installed on the Storage Box user/subaccount with `install-ssh-key` |
| pinned SSH host key | `/etc/domum-core/secrets/hetzner_storagebox_known_hosts` |
| Hetzner web/account password | not stored by domum-core |

## 0. Set temporary shell helpers

These variables are only helpers for copy-paste commands in this terminal
session. They do not save anything permanently. The permanent config edit
happens in step 7.

Replace the example user and host with the Storage Box user or subaccount you
actually use.

```bash
HETZNER_USER="uXXXXXX"
HETZNER_HOST="uXXXXXX.your-storagebox.de"
HETZNER_REPO="sftp:${HETZNER_USER}@${HETZNER_HOST}:domum-core-restic"
```

The repository path is intentionally relative. Hetzner Storage Box only allows
writes below the login root (`/home` on port `23`). Do not use
`:/./domum-core-restic` here: restic treats that as `/domum-core-restic` and
repository initialization fails with `SSH_FX_FAILURE`.

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
sudo chown root:root /etc/domum-core/secrets/hetzner_storagebox_ed25519 /etc/domum-core/secrets/hetzner_storagebox_ed25519.pub
sudo chmod 600 /etc/domum-core/secrets/hetzner_storagebox_ed25519
sudo chmod 644 /etc/domum-core/secrets/hetzner_storagebox_ed25519.pub
```

Show the public key:

```bash
sudo sed -n '1p' /etc/domum-core/secrets/hetzner_storagebox_ed25519.pub
```

If you use `zsh`, keep the explicit `chown` paths above. A glob such as
`hetzner_storagebox_ed25519*` can fail with `zsh: no matches found` when sudo
and shell expansion disagree.

The public key is installed after the host key is pinned in the next step. The
Hetzner Console SSH-key page for cloud servers is not enough for Storage Box
SFTP access.

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

## 6. Install the public key on the Storage Box

Hetzner Storage Box may not show an SSH-key field in the UI. Install the public
key with the Storage Box password once:

```bash
sudo ssh -p 23 \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile=/etc/domum-core/secrets/hetzner_storagebox_known_hosts \
  "${HETZNER_USER}@${HETZNER_HOST}" \
  install-ssh-key < /etc/domum-core/secrets/hetzner_storagebox_ed25519.pub
```

Expected output includes both formats:

```text
Key No. 1 (ssh-ed25519 domum-core-hetzner-backups) was installed in RFC4716 format
Key No. 1 (ssh-ed25519 domum-core-hetzner-backups) was installed in OpenSSH format
```

This password is the Storage Box user's password. It is not stored by
domum-core. Future backups use the SSH key and restic password file instead of
prompting interactively.

## 7. Test SFTP login

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

Because this test sets `PasswordAuthentication=no`, success proves key auth is
working and scheduled backups should not prompt for the Storage Box password.

## 8. Configure the Hetzner target

This is the permanent place for your Hetzner user and host:

```bash
sudo env TERM=xterm-256color nano /opt/domum-core/config/domum-backup.conf
```

Use another root editor such as `sudo nvim` if preferred. `sudoedit` can refuse
to edit this file when the repository directory is writable by your user.

Paste the block below over the existing Hetzner section. If Hetzner is your
only target, `BACKUP_TARGETS="hetzner"` is correct. If you also use a local
NAS/disk target, keep `BACKUP_TARGETS="local hetzner"`.

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

Validate that the config still parses:

```bash
sudo domum-core configure --validate
```

## 9. Initialize the restic repository

```bash
sudo domum-core backups init hetzner
```

Success looks like `Repository ready` and a metadata file under
`/var/lib/domum-core/backups/hetzner-repo.env`.

If the command says the repository is already initialized, that is fine.

## 10. Create a fresh recovery pack

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

## 11. Run the first backup

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

## 12. Enable scheduled backups

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

Success looks like a future `domum-core-backups.timer` entry. A later
`backups snapshots` should show an additional snapshot created by the timer.

## 13. Enable Hetzner automatic snapshots

Storage Box snapshots are not a replacement for restic backups, and they are not
an encryption feature. They are useful protection against accidental deletion or
corruption of the encrypted restic repository.

Recommended BX11 automatic snapshot settings:

| Setting | Value |
|---|---|
| Interval | Daily |
| Max amount | 10 |
| Execution time (UTC) | `10:00` |
| Day of month | Leave empty / not used for daily snapshots |

`10:00 UTC` is intentionally after the local `02:30` backup timer, its random
delay, and the weekly recovery/verify timers. It is also safer across daylight
saving time than trying to target exactly `05:00` local time.

Hetzner snapshots live on the same Storage Box and consume Storage Box capacity
as data changes. Restoring a snapshot rolls the Storage Box back to that point
and can remove newer files and newer snapshots, so restore snapshots only during
an actual recovery procedure.

## Security model

The Storage Box should be treated as remote storage, not as the encryption
boundary. The backup contents are protected by restic encryption before they are
sent to Hetzner.

- Someone with Storage Box read access but without the restic password should
  not be able to read backed-up files.
- Someone with Storage Box write/delete access can still delete or corrupt the
  repository. Hetzner snapshots reduce that risk.
- Someone with root access on the Pi can read live data and the restic password
  file, so they can decrypt backups. That is inherent to unattended backups.
- Save `/etc/domum-core/secrets/restic_password_hetzner` off-box. Without it,
  the restic repository cannot be restored.
- Save the AGE private key off-box. Without it, recovery-pack `.age` files
  cannot be decrypted.

## Daily operations

Use these commands to inspect the setup later:

```bash
sudo domum-core backups snapshots
sudo domum-core backups history
sudo domum-core backups prune --dry-run
sudo domum-core checkup
```

How to read the output:

- `backups snapshots` lists restic snapshots. A new row after the nightly timer
  proves scheduled offsite backups are running.
- `backups history` records the service-backup phase and restic phase exit
  codes. `service_rc=0 restic_rc=0` means both phases succeeded.
- `backups prune --dry-run` shows which snapshots retention would keep or
  remove without deleting anything.
- `backups verify` runs `restic check` against the remote repository.
- `checkup` should report at least one enabled restic target and a fresh backup.

## Troubleshooting

`Permission denied (publickey)` means the public key is missing from Hetzner or
was added to the wrong Storage Box user or subaccount. Re-run step 6 for the
same user configured in `BACKUP_TARGET_HETZNER_REPOSITORY`.

`Permission denied (publickey,password)` during the key-only SFTP test means the
Storage Box did not accept the SSH key. The Hetzner Cloud Console SSH-key list
does not authorize Storage Box SFTP by itself; use `install-ssh-key`.

`Host key verification failed` means the pinned known-hosts file does not match
the server you reached. Recheck the host name and fingerprint in step 5.

`repository not initialized` means the target is reachable but restic has not
created its repository yet. Run:

```bash
sudo domum-core backups init hetzner
```

`MkdirAll /domum-core-restic/locks: sftp: "Failure" (SSH_FX_FAILURE)` means the
repository path is absolute. Use `sftp:uXXXXXX@uXXXXXX.your-storagebox.de:domum-core-restic`,
not `:/./domum-core-restic`.

Older versions of `domum-core configure --validate` may falsely reject real
`uXXXXXX.your-storagebox.de` hostnames as placeholders. The repository path is
valid when it uses your real `uNNNNNN` user and the relative `:domum-core-restic`
path.

A stale Hetzner warning in `checkup` means another target may still be fresh,
but the offsite destination needs attention. Inspect the last backup run:

```bash
sudo journalctl -u domum-core-backups.service -n 120 --no-pager
sudo domum-core backups history
```

Do not fix SFTP problems by removing the key file, weakening file permissions,
or disabling host-key checking. Fix the configured user, key, host, or pinned
fingerprint instead.
