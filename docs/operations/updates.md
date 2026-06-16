# Container updates

Container update behavior is configured per app in `config/domum.conf`.
Category labels such as infrastructure, home automation core, and stateful app
are documentation/UI labels only. They do not control update behavior globally.

## Commands

```bash
sudo domum-core updates check
sudo domum-core updates status
sudo domum-core updates apply homeassistant --dry-run
sudo domum-core updates apply homeassistant
sudo domum-core updates apply-auto --dry-run
sudo domum-core updates apply-auto
sudo domum-core updates history
```

Deprecated compatibility:

```bash
sudo domum-core updates candidates
sudo domum-core updates apply --class A
sudo domum-core updates apply --class B
sudo domum-core updates apply --class C
```

The class apply form prints a warning and uses app-by-app auto-update logic.

## Policy settings

Each app has two settings:

```bash
HOMEASSISTANT_AUTO_UPDATE=0
HOMEASSISTANT_UPDATE_DELAY_DAYS=14
```

`*_AUTO_UPDATE=1` allows `updates apply-auto` to update the app after the delay.
`*_AUTO_UPDATE=0` records candidates but requires manual
`updates apply <app>`.

`*_UPDATE_DELAY_DAYS` is the number of stable days a candidate image digest must
remain unchanged before it can apply. If a newer candidate digest appears before
the delay expires, domum-core resets the first-seen timestamp and waits the full
delay again.

Default philosophy:

- Infrastructure can auto-update after short delays.
- Home automation core is manual by default.
- Stateful apps are manual by default.
- Vaultwarden is manual because it contains sensitive data.
- Home Assistant is manual because it is the main automation hub.

## Candidate lifecycle

`updates check` checks enabled services, compares the running image digest with
the current image digest for the configured image reference, and records:

- current/running digest
- candidate digest
- first-seen timestamp
- last-seen timestamp

`updates status` shows each enabled app, auto-update setting, required delay,
candidate status, and whether a backup gate applies.

## Backup gates

These services require fresh backups before update:

- `homeassistant`
- `mariadb`
- `actual-budget`
- `vaultwarden`
- `obsidian-sync`
- `zigbee2mqtt`
- `zwave-js-ui`
- `nodered`
- `mqtt`
- `adguard-home`

Freshness is controlled by `BACKUP_MAX_AGE_HOURS`. A fresh service-level backup
is required. If a restic target is enabled, a fresh restic heartbeat is also
required. Manual override is possible with `--force`; the CLI prints a clear
warning before proceeding.

## Host OS updates

Host OS package updates are separate:

```bash
sudo domum-core os-updates check
sudo domum-core os-updates security-apply --dry-run
sudo domum-core os-updates security-apply
sudo domum-core os-updates history
```
