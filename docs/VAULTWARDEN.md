# Vaultwarden

Vaultwarden is optional and disabled/enabled through `ENABLE_VAULTWARDEN`.

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://vault.${DOMUM_DOMAIN}` unless `VAULTWARDEN_DOMAIN`
overrides it. Public signups and invitations default to false:

```bash
VAULTWARDEN_SIGNUPS_ALLOWED=false
VAULTWARDEN_INVITATIONS_ALLOWED=false
```

Data lives at `/opt/domum-core/compose/security/vaultwarden/data` and is included by
`domum-core backups run` when `BACKUP_VAULTWARDEN=1`.

Recovery is a file restore of that data directory followed by `sudo domum-core apply`.
