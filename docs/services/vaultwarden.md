# Vaultwarden

Vaultwarden is the private password manager. It is compatible with Bitwarden
apps and browser extensions.

Use it for:

- personal and family passwords
- secure notes
- browser autofill through the Bitwarden extension

## Enable the Service

Vaultwarden is enabled or disabled with `ENABLE_VAULTWARDEN`.

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

## First Login

Because signups are locked down by default, open registration only long enough
to create the first account.

1. Run `sudo domum-core configure`.
2. Set `VAULTWARDEN_SIGNUPS_ALLOWED=true`.
3. Run `sudo domum-core apply`.
4. Open `https://vault.${DOMUM_DOMAIN}`.
5. Create your first account.
6. Run `sudo domum-core configure` again.
7. Set `VAULTWARDEN_SIGNUPS_ALLOWED=false`.
8. Run `sudo domum-core apply` again.

Do not leave public signups enabled. Anyone who can reach the site could create
an account while signups are open.

## Daily Use

Use Vaultwarden like Bitwarden:

- Web vault: open `https://vault.${DOMUM_DOMAIN}` in a browser.
- Browser extension: install the Bitwarden extension, then set the server URL to
  `https://vault.${DOMUM_DOMAIN}` before logging in.
- Mobile app: install the Bitwarden app, tap the self-hosted/server option, and
  set the server URL to `https://vault.${DOMUM_DOMAIN}`.

Use your Vaultwarden email and master password in every Bitwarden client. Keep
the master password somewhere safe until you are confident you can log in from
more than one device.

## Adding Family Members

The safest simple path is to briefly enable signups, let the family member
create their account, then disable signups again.

Only do this while you are available to confirm the account was created.

## Backups and Recovery

Data lives at `/opt/domum-core/compose/security/vaultwarden/data` and is included by
`domum-core backups run` when `BACKUP_VAULTWARDEN=1`.

`domum-core backups run` also creates a quiesced service archive under
`/var/lib/domum-core/service-backups/vaultwarden` by briefly pausing the
container while the tar is written. That archive is included in restic and is the
preferred SQLite restore source after a Pi loss; the raw data directory remains
available as a second copy.

Recovery is a file restore of the selected Vaultwarden data source followed by
`sudo domum-core apply`.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.

If login works in the web vault but not in an app, check that the app is using
the custom server URL `https://vault.${DOMUM_DOMAIN}` and not the public
Bitwarden cloud.
