# Production audit + zigbee2mqtt → HA fix + CI workflow

## Context

`domum-core` is a production Raspberry Pi home-core stack (Home Assistant, zigbee2mqtt, MQTT, MariaDB, Traefik, etc.) deployed via a single `domum apply` command that runs `docker compose` against a curated list of files.

Two motivations for this work:

1. **z2m is publishing but HA shows nothing.** Reading the compose files reveals why: `mqtt` is attached only to `domum-internal`; `homeassistant` is attached only to `domum-proxy` + `domum-data`. There is no shared network between them, so HA cannot reach `mqtt://mqtt:1883` regardless of how the MQTT integration is configured in the HA UI. zigbee2mqtt itself works because it shares `domum-internal` with mosquitto.
2. **Audit before more services get added.** Several smaller discrepancies exist (inconsistent `domum-data` declarations, a path typo in `adguard-home.yml`, a committed Zigbee network key, an invalid `NIGHT_UP_TIME`, etc.) that are easier to fix as a batch.
3. **No CI yet.** A single bad indent in a compose file currently only fails at `domum apply` time on the Pi. A GitHub Actions workflow gating PRs catches these earlier.

Rollout: plan only — user will apply manually on the Pi during a maintenance window.

---

## Findings + Fixes

### 1. 🔴 HA cannot reach MQTT (the reported z2m → HA issue)

**File:** `compose/automation/home-assistant.yml`

Add `domum-internal` to the `homeassistant` service's network list and to the file's top-level `networks:` block (as `external: true`).

```yaml
services:
  homeassistant:
    networks:
      - domum-proxy
      - domum-data
      - domum-internal      # NEW

networks:
  domum-proxy:
    external: true
  domum-data:
    external: true          # see fix #2
  domum-internal:           # NEW
    external: true
```

After apply, in the HA UI go to **Settings → Devices & Services → Add Integration → MQTT** and point it at host `mqtt`, port `1883` (no user/pass unless mosquitto is configured for auth — see finding #8). Z2M HA-discovery will then populate entities automatically because `homeassistant: enabled: true` is already set in `compose/automation/zigbee2mqtt/configuration.yaml:1`.

### 2. 🟡 Inconsistent `domum-data` network declarations

**Files:**
- `compose/base.yml` — does **not** declare `domum-data` (declares only `domum-proxy`, `domum-internal`)
- `bin/domum` `ensure_networks()` (~line 185) — does not create `domum-data`
- `compose/automation/mariadb.yml`, `compose/automation/home-assistant.yml`, `compose/automation/zwave-js-ui.yml` declare it as `name: domum-data, driver: bridge` (inline create)
- `compose/automation/music-assistant.yml`, `compose/productivity/actual-budget.yml` declare it as `external: true`

This works today only because the first compose file processed creates the network. Standardize:

- Add `domum-data:` (driver bridge) to `compose/base.yml` `networks:`
- Add `"domum-data"` to `nets=(...)` in `bin/domum:ensure_networks` (~L185)
- Change every service file using `domum-data` to declare it as `external: true` (same pattern as `domum-proxy` / `domum-internal`)

### 3. 🟡 AdGuard bind-path typo

**File:** `compose/networking/adguard-home.yml:12-13`

Paths reference `/opt/domum-core/compose/network/adguard/...` (singular). The actual directory is `compose/networking/adguard/` (plural). On a fresh host Docker silently creates an empty `compose/network/adguard/...` and AdGuard starts with no config.

Fix the two volume paths to `compose/networking/adguard/{work,conf}`. **Production note:** check whether the running Pi has a stray `compose/network/adguard/` directory with the real config — if so, move its contents to `compose/networking/adguard/` before restarting the container.

### 4. 🟡 Invalid `NIGHT_UP_TIME="24:00"`

**File:** `config/domum.conf:52`

`24:00` is rejected by systemd `OnCalendar=` (max `23:59`). Change to `00:00` if midnight is intended. `bin/domum:schedule_install` writes the timer file verbatim — this would silently fail on the next `domum schedule install`.

### 5. 🟡 Committed Zigbee network key

**File:** `compose/automation/zigbee2mqtt/configuration.yaml:16-32`

The 16-byte `network_key` is committed in plaintext. Anyone with repo access can decrypt the Zigbee traffic. zigbee2mqtt supports `!secret` indirection.

Plan:
- Create `compose/automation/zigbee2mqtt/secret.yaml` (gitignored) containing `network_key: [...]`
- Replace inline key in `configuration.yaml` with `network_key: !secret network_key`
- Add `compose/automation/zigbee2mqtt/secret.yaml` to `.gitignore`
- Document the rotation as a separate operational task (re-pairing devices may be required — likely defer until next maintenance window)

For now, **commit the structural change but keep the existing key in place** so devices keep working. Rotation is a deliberate, scheduled step.

### 6. 🟡 zwave-js-ui publishes host port 3000

**File:** `compose/automation/zwave-js-ui.yml:19-20`

Port `3000:3000` is the WebSocket port and is exposed on the host with no auth. The web UI is `8091` and is already routed via Traefik. Either:
- Remove the `3000:3000` line (recommended — HA can reach WS over `domum-data` by service name), or
- Document why it's needed and bind to `127.0.0.1:3000`.

### 7. 🟡 Unused volume declarations in `base.yml`

**File:** `compose/base.yml:11-23`

Most named volumes here (`mosquitto-data`, `mosquitto-log`, `zigbee2mqtt-data`, `homeassistant-config`, `adguard-work`, `adguard-conf`, `jellyfin-config`, `jellyfin-cache`) are never used — the corresponding services use bind mounts to `/opt/domum-core/compose/...`. Drop the unused entries; keep only the ones actually referenced (`portainer-data`, `uptime-kuma-data`, `traefik-letsencrypt` if used). Low risk: removing an unused declaration changes nothing at runtime, but `docker compose down -v` semantics get clearer.

### 8. 🟡 MQTT broker has no auth + port 1883 published to host

**File:** `compose/automation/mqtt.yml`, `compose/automation/mqtt/config/`

`secrets.example.yaml` declares `mqtt_user` / `mqtt_pass`, implying auth was intended, but mosquitto's config dir is empty and 1883 is published to the host. Today the broker is open on the LAN.

Out of scope for the structural fix but **flag for a follow-up**: write `mosquitto.conf` with `allow_anonymous false` + `password_file` and create the password file under `/etc/domum-core/secrets/mqtt/`. Once enabled, HA + z2m + nodered need credentials. Defer to a separate session.

### 9. 🟡 `iot_vlan50` ambiguity

**Files:** `bin/domum:ensure_networks` creates it as a default bridge; `compose/automation/frigate.yml`, `compose/automation/go2rtc.yml` declare it as `external: true`.

The name implies a macvlan to physical VLAN 50, but the bridge created by `ensure_networks` is just a docker bridge. If the user's actual setup uses a real macvlan (likely, for camera discovery), it must be created out-of-band before `ensure_networks` runs (the `inspect` check passes and the auto-create is skipped). Document this in the README rather than change it — likely already correct on the running Pi.

### 10. ✅ Add GitHub Actions CI workflow

**New file:** `.github/workflows/validate.yml`

Single workflow, triggered on `push` and `pull_request` to `main`. Jobs (all run in parallel):

| Job | Tool | What it checks |
| --- | --- | --- |
| `yamllint` | `adrienverge/yamllint` | All `**/*.{yml,yaml}` against a relaxed config (line-length warn only, document-start disabled, allow `on:` in workflow keys) |
| `shellcheck` | `ludeeus/action-shellcheck` | `install.sh`, `bin/domum`, `bin/night-profile.sh` |
| `gitleaks` | `gitleaks/gitleaks-action` | Full history scan; will flag the existing committed Zigbee key (finding #5) — add `.gitleaks.toml` allowlist for that path until rotation happens, or fix #5 first |
| `compose-validate` | `docker compose config` | Iterates every combination of `ENABLE_*=1` env vars and runs `docker compose -f base.yml -f <svc>.yml config -q`. Simplest first cut: render with **all** enabled. |

Add a top-level `yamllint` config `.yamllint.yml` and a minimal `.gitleaks.toml` so the workflow is reproducible locally.

---

## Critical files to modify

- `compose/automation/home-assistant.yml` — add `domum-internal` (fix #1)
- `compose/base.yml` — declare `domum-data`, trim unused volumes (fixes #2, #7)
- `bin/domum` — add `domum-data` to `ensure_networks` (fix #2)
- `compose/automation/mariadb.yml`, `home-assistant.yml`, `zwave-js-ui.yml` — change `domum-data` to `external: true` (fix #2)
- `compose/networking/adguard-home.yml` — fix `network` → `networking` typo (fix #3)
- `config/domum.conf` — `24:00` → `00:00` (fix #4)
- `compose/automation/zigbee2mqtt/configuration.yaml` + new `secret.yaml` + `.gitignore` (fix #5)
- `compose/automation/zwave-js-ui.yml` — drop or bind-local the `3000:3000` publish (fix #6)
- **NEW** `.github/workflows/validate.yml`, `.yamllint.yml`, `.gitleaks.toml` (fix #10)

## Reusable utilities found

- `bin/domum:compose_files_for_enabled_services` (L75) — already enumerates all enabled compose files. The CI compose-validate job can shell out to this same function with a synthetic config to render the full graph, rather than reimplementing the file list in YAML.
- `bin/domum:ensure_networks` (~L185) — single point of truth for required external networks. Adding `domum-data` there fixes the inconsistency everywhere at once.

## Out of scope (track separately)

- Zigbee network-key rotation (operational, requires re-pairing)
- Mosquitto auth (#8)
- macvlan vs bridge for `iot_vlan50` (#9)

---

## Verification

After applying on the Pi:

1. `docker network inspect domum-internal | jq '.[0].Containers | keys'` — confirm `homeassistant` appears alongside `mqtt`, `zigbee2mqtt`.
2. `docker exec homeassistant getent hosts mqtt` — should resolve to a container IP.
3. In HA UI: **Settings → Devices & Services → Add Integration → MQTT** → broker `mqtt`, port `1883`. After adding, the **MQTT** integration tile should show "X devices" pulled from z2m's discovery topics.
4. `docker exec mqtt mosquitto_sub -t 'zigbee2mqtt/bridge/devices' -C 1` — confirms z2m is publishing the device list HA needs.
5. `sudo domum apply` runs cleanly with no `network does not exist` warnings.
6. CI workflow: open a PR with an intentional YAML error → confirm `yamllint` fails; revert. Open a PR adding a fake AWS key in a comment → confirm `gitleaks` fails; revert.
7. `sudo domum schedule install` succeeds without complaint about `NIGHT_UP_TIME`.

If anything fails, **do not** edit files on the Pi directly — fix in the repo and re-run `sudo domum update && sudo domum apply` per the README's stated workflow.
