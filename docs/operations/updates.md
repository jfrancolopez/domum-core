# Container updates

Container update behavior is configured per app in `config/domum.conf`.
Category labels such as infrastructure, home automation core, and stateful app
are documentation/UI labels only. They do not control update behavior globally.

## Target model: low-maintenance, not stale

The desired operating model is: update automatically where breakage is unlikely,
gate every update on fresh backups, and nag when manual/pinned services are
getting old. The goal is neither reckless freshness nor pinning everything until
it fossilizes.

| Tier | Services | Policy |
|---|---|---|
| OS security | Debian packages | Automatic security patches; no automatic reboot |
| Safe infrastructure | Traefik within current major, AdGuard | Auto-update after a short delay |
| Normal apps | Actual Budget, Vaultwarden, Music Assistant, ESPHome, Node-RED, Obsidian Sync | Auto-update after backup + delay |
| Dangerous core/stateful | MariaDB, Home Assistant, Zigbee2MQTT, Z-Wave JS UI | Manual approval, with age nags so they are not forgotten |

Why this split:

- MariaDB and Home Assistant can involve data/schema migrations.
- Zigbee2MQTT and Z-Wave JS UI can affect radio networks and device behavior.
- Vaultwarden is security-sensitive, so timely backup-gated updates are better
  than leaving it manual forever.
- Traefik should be pinned by major version, not frozen forever: `traefik:v3`
  keeps v3 updates flowing but prevents an unattended v4 config break.

Current caveat: task 36 is still required before this model is safe unattended.
Today `updates check` still downloads images with `docker pull`, which means a
later `apply` can deploy an image outside the delay/backup gate. Until task 36
lands, treat container updates as supervised.

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

Current defaults:

- Infrastructure can auto-update after short delays.
- Home automation core is manual by default.
- Stateful apps are mostly manual until task 36 implements the safer unattended
  pipeline and image-age nags.
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
