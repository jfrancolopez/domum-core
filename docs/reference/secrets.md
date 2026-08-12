# Secrets

All secrets live **outside the git repo** at `/etc/domum-core/secrets/`
(mode `0700`, owner root). This path is standardized — older drafts of
`install.sh` / `night-profile.sh` referenced `/opt/domum-core/secrets`; that
drift is fixed.

`domum-core checkup` warns if the directory is not `0700` / owner root.

## Inventory

| File | Used by |
|---|---|
| `cloudflare_api_token` | Traefik DNS-01 ACME |
| `mariadb/mariadb.env` | MariaDB container env (`MARIADB_ROOT_PASSWORD`, etc.) |
| `mqtt_password` | cleartext password for Home Assistant/Zigbee2MQTT MQTT clients |
| `mosquitto_passwd` | root-only source Mosquitto password hashes for MQTT clients |
| `traefik_dashboard_users` | Traefik dashboard basic-auth |
| `tailscale_authkey` | Optional one-time Tailscale re-authentication |
| `restic_password_local` | restic key for the LOCAL backup target |
| `restic_password_hetzner` | restic key for the HETZNER backup target |
| `hetzner_storagebox_ed25519` | SSH key for the Hetzner Storage Box |
| `hetzner_storagebox_known_hosts` | pinned host key for the Storage Box |
| `recovery-age.pub` | **public** AGE key — encrypts the recovery pack |
| `recovery_pack_smtp_username` / `_password` | optional recovery-pack email |
| `glance-beszel.env` | optional Glance Beszel readonly username/password and approved system labels/IDs |

Future Glance dashboard integrations may add more read-only API keys or private
feed URLs. Add names here only when a later widget task approves a specific
credential and source.

`glance-beszel.env` is the only supported Glance Beszel credential location;
separate username/password files are intentionally not used.

Repo-tree secrets (bind-mounted, gitignored): HA `secrets.yaml`, Zigbee2MQTT
`secret.yaml`.

Zigbee2MQTT `secret.yaml` contains the live Zigbee network key. If the key needs
to change, use the planned maintenance runbook:
[Zigbee network key rotation](zigbee-key-rotation.md).

## Traefik Dashboard Auth

The dashboard basic-auth file is mounted from
`/etc/domum-core/secrets/traefik_dashboard_users` to
`/run/secrets/traefik_dashboard_users` in the Traefik container. Do not create
or commit an in-repo `usersfile`.

Generate it on the host with:

```bash
sudo apt-get install -y apache2-utils
sudo sh -lc 'umask 077; htpasswd -nbB USERNAME "STRONG_PASSWORD_HERE" > /etc/domum-core/secrets/traefik_dashboard_users'
```

## AGE keypair for the recovery pack

The recovery pack is encrypted to an AGE recipient. **Generate the keypair on a
trusted machine, NOT on the Pi**, and keep the private key offline:

```bash
age-keygen -o recovery-age.key          # private key — store offline (password manager / USB)
grep 'public key' recovery-age.key      # copy the age1... line
```

The `recovery-age.key` file is the private key. Save its full contents in your
password manager or another offline location. The line that starts with
`AGE-SECRET-KEY-` is the secret material. The `age1...` value printed in the
comment is the public key.

Put **only the public key** on the Pi:

```bash
echo 'age1xxxx...' | sudo tee /etc/domum-core/secrets/recovery-age.pub
sudo chmod 644 /etc/domum-core/secrets/recovery-age.pub
```

`domum-core recovery-pack create` refuses (with instructions) if the public key
is missing, and **never auto-generates or rotates** keys. The private key is the
only way to decrypt a recovery pack — losing it makes every pack unreadable.

If the private key is lost, generate a new keypair, replace
`/etc/domum-core/secrets/recovery-age.pub` with the new public key, and create a
new recovery pack. Old recovery packs encrypted to the lost key remain
unreadable.

Test a downloaded recovery-pack email attachment on the machine that has the
private key:

```bash
age -d -i recovery-age.key recovery-pack-YYYYMMDD-HHMMSS.tar.age > recovery-pack.tar
tar -tzf recovery-pack.tar
```

If `tar -tzf` lists files, the AGE private key can decrypt the recovery pack.
Keep both the AGE private key and the Hetzner restic password in secure notes;
they protect different recovery steps.

## Rules

- Secrets are **never** rotated automatically.
- The recovery pack bundles copies of small secret files (encrypted). Treat the
  `.age` archive as sensitive even though it's encrypted.
- Backup-target metadata in the recovery pack contains repo URLs but **not**
  cleartext restic passwords beyond the secret-file copies themselves.
