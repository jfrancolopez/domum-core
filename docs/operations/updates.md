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

Current caveat: task 36 is landing in separate safety commits. `updates check`
is pull-free and uses registry manifest inspection, so it no longer downloads
new images during a read-only check. `updates apply` verifies that the pulled
image still matches the aged candidate before deployment. The optional
`domum-core-updates-apply.timer` can run `updates apply-auto` each morning, but
keep it disabled until you have supervised one full cycle on the Pi. Treat
container updates as supervised until the remaining task 36 rollback piece
lands.

## Commands

```bash
sudo domum-core updates check
sudo domum-core updates status
sudo domum-core updates apply homeassistant --dry-run
sudo domum-core updates apply homeassistant
sudo domum-core updates apply-auto --dry-run
sudo domum-core updates apply-auto
sudo domum-core updates rollback nodered --dry-run
sudo domum-core updates rollback nodered
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

Each app has update policy settings:

```bash
HOMEASSISTANT_AUTO_UPDATE=0
HOMEASSISTANT_UPDATE_DELAY_DAYS=14
```

`*_AUTO_UPDATE=1` allows `updates apply-auto` to update the app after the delay.
`*_AUTO_UPDATE=0` records candidates but requires manual
`updates apply <app>`.

MariaDB, Home Assistant, Zigbee2MQTT, and Z-Wave JS UI are protected manual
services. `updates apply-auto` treats them as auto-update disabled even if an old
live config sets `*_AUTO_UPDATE=1`; use `updates apply <app>` for supervised
maintenance.

`*_UPDATE_DELAY_DAYS` is the number of stable days a candidate image digest must
remain unchanged before it can apply. If a newer candidate digest appears before
the delay expires, domum-core resets the first-seen timestamp and waits the full
delay again.

Checkup also warns when images look forgotten:

```bash
UPDATE_ROT_AUTO_DAYS=60
UPDATE_ROT_MANUAL_DAYS=270
```

Auto-update services older than `UPDATE_ROT_AUTO_DAYS` usually mean the pipeline
is stuck. Manual services older than `UPDATE_ROT_MANUAL_DAYS` are due for a pin
or update-policy review.

Some services also have explicit image variables in `config/domum.conf`:

```bash
TRAEFIK_IMAGE="traefik:v3"
HOMEASSISTANT_IMAGE="ghcr.io/home-assistant/home-assistant:stable"
MARIADB_IMAGE="mariadb:12.2"
```

Move these deliberately when you want to change the pinned stream. For MariaDB,
take a fresh backup first and treat major/minor changes as a planned database
upgrade. For Traefik, keep the major pin (`v3`) until you are ready to review a
future major's migration notes.

Current defaults:

- Traefik and AdGuard can auto-update after short delays.
- Normal apps can auto-update after backup and delay gates.
- MariaDB, Home Assistant, Zigbee2MQTT, and Z-Wave JS UI are protected manual
  services because they can involve database migrations, HA behavior changes,
  or radio network/device risk.

## Candidate lifecycle

`updates check` checks enabled services without pulling images. It compares the
running image's repo digest with the registry manifest digest for the configured
image reference, and records:

- current/running digest
- candidate digest
- first-seen timestamp
- last-seen timestamp

`updates status` shows each enabled app, auto-update setting, required delay,
candidate status, and whether a backup gate applies.

`updates apply <app>` pulls the app image only after the delay and backup gates
pass. Before recreating the container, it verifies that the local tag's pulled
repo digest still matches the recorded candidate digest. If the registry moved
to a newer digest during the waiting period, domum-core records the newer digest
as a fresh candidate and resets the delay window. `--force` can override this,
but should be reserved for supervised maintenance.

`updates rollback <app>` retags the previous local image from the latest
successful update history entry and recreates only that compose service. It is a
local-image rollback, not a data/schema rollback. For config-pinned services
(`traefik`, `home-assistant`, `mariadb`), move the image pin in
`config/domum.conf` and apply deliberately instead.

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
