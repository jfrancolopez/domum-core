# Recovery pack

The recovery pack stores host identity and rebuild metadata in an AGE-encrypted
archive. It is not a replacement for restic service/data backups.

The Pi stores only the AGE public key at
`/etc/domum-core/secrets/recovery-age.pub`. The AGE private key must be stored
offline or in secure notes. If the private key is lost, existing `.tar.age`
recovery packs cannot be decrypted.

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

## Decryption test

After receiving a recovery-pack email attachment, download the `.tar.age` file
to the machine that has the private key and run:

```bash
age -d -i recovery-age.key recovery-pack-YYYYMMDD-HHMMSS.tar.age > recovery-pack.tar
tar -tzf recovery-pack.tar
```

Success means the attachment decrypted and the resulting tar archive is
readable. Store the full AGE private-key file contents in secure notes, not just
the public `age1...` line.
