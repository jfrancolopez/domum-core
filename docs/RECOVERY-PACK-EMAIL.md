# Recovery Pack Email

Recovery packs are AGE-encrypted first and emailed second. The Pi must only have the AGE
public key; generate and keep the private key offline.

```bash
ENABLE_RECOVERY_EMAIL=1
RECOVERY_EMAIL_PROVIDER="gmail"
RECOVERY_EMAIL_TO="you@example.com"
RECOVERY_EMAIL_FROM="you@gmail.com"
GMAIL_APP_PASSWORD_FILE="/etc/domum-core/secrets/gmail-app-password"
```

Commands:

```bash
sudo domum-core recovery-pack create
sudo domum-core recovery-pack send-latest --dry-run
sudo domum-core recovery-pack send-latest
sudo domum-core recovery-pack email-test
```

`email-test` sends a tiny encrypted attachment so SMTP and decryption can be verified
without sending a full recovery pack.
