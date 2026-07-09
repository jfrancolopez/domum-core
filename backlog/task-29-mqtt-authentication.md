# Task 29 — MQTT authentication (close the anonymous LAN-writable broker)

## Objective
Require credentials on the Mosquitto broker. Today anyone on the LAN can
publish to the bus that controls the house.

## Background / current behavior
- `compose/automation/mqtt/config/mosquitto.conf`: `allow_anonymous true`.
- `compose/automation/mqtt.yml` publishes `1883:1883` on the host.
- **ufw does not protect Docker-published ports** (Docker inserts its own
  iptables FORWARD rules ahead of ufw), so the "deny incoming" firewall from
  the install doc does not apply — 1883 is open to the entire LAN.
- Consequence: any LAN device (or compromised IoT gadget) can publish
  `zigbee2mqtt/<device>/set` — locks, plugs, alarms — and subscribe to
  everything, no credentials needed.
- Irony check: HA's `secrets.example.yaml` already contains `mqtt_user` /
  `mqtt_pass` placeholders — auth was clearly intended and never wired up.

## Why the port stays published
`checkup` probes `127.0.0.1:1883`, and LAN MQTT clients (ESPHome devices or
other sensors publishing over Wi-Fi) may need the broker. If, during
implementation, an audit of connected clients (`mosquitto_sub -t '$SYS/#'`,
z2m/HA only?) shows **no LAN clients exist**, prefer the even simpler fix:
bind the port to localhost (`127.0.0.1:1883:1883`) or drop the mapping
entirely (containers reach `mqtt:1883` via the docker network regardless).
Auth is still worth having even then — defense in depth costs two files.

## Desired behavior
- `allow_anonymous false`; a password file with two or three accounts:
  `ha`, `z2m`, and optionally `iot` (shared by LAN sensor devices — one
  credential for that class keeps maintenance near zero).
- Password file lives at `/etc/domum-core/secrets/mosquitto_passwd`
  (generated with `mosquitto_passwd`, mode 0600 → but note mosquitto in the
  container runs as its own uid; verify read works, may need 0640 + group or
  a copy into the config bind mount excluded from git — decide during
  implementation; keep it out of the repo tree either way, or gitignore it
  explicitly if it must sit in the mounted config dir).
- z2m `configuration.yaml` gains `mqtt.user/password` via its `!secret`
  mechanism (`secret.yaml`, already gitignored).
- HA's MQTT integration is UI-configured — update credentials in the UI
  (document the click-path); `secrets.yaml` entries feed it if the YAML
  config is used.

## Implementation plan (maintenance-window task — order matters)
1. Take a backup: `sudo domum-core backups run`.
2. Create the password file: `mosquitto_passwd -c -b <file> ha <pw>` etc.
   Generate passwords once, store them in Vaultwarden... which depends on
   nothing MQTT — fine.
3. Mount the passwd file into the container (compose volume line), update
   `mosquitto.conf`: `allow_anonymous false`, `password_file /mosquitto/config/passwd`.
4. Pre-stage credentials in consumers BEFORE flipping the broker:
   z2m secret.yaml + configuration.yaml; HA UI (it will briefly fail auth
   until the broker flips — acceptable seconds-long gap) ;
   any ESPHome devices' MQTT blocks (if used — most ESPHome devices here
   likely use the native HA API; verify, and note the finding).
5. `sudo domum-core apply` (recreates mqtt) → watch `docker logs mqtt` for
   auth denials; fix stragglers.
6. Verify: `mosquitto_pub -h <lan-ip> -t test -m x` **without** creds fails;
   with creds succeeds; z2m devices report; HA MQTT integration connected.
7. Update docs: `docs/reference/secrets.md` inventory row;
   `docs/services/home-assistant.md` MQTT note; mention the Docker/ufw
   caveat where the port mapping is discussed.

## Affected files
- `compose/automation/mqtt/config/mosquitto.conf`
- `compose/automation/mqtt.yml` (passwd mount; possibly 127.0.0.1 bind)
- `compose/automation/zigbee2mqtt/configuration.yaml` (+ untracked secret.yaml)
- `docs/reference/secrets.md`, `docs/services/home-assistant.md`
- (checkup's tcp_probe keeps working — a TCP connect needs no auth)

## Testing plan
Steps 5–6 above are the test. Also: reboot test within the window (broker
comes up with auth, clients reconnect unattended).

## Rollback strategy
Set `allow_anonymous true` back and `apply` — 30 seconds. Keep the old conf
line commented in place during the window.

## Dependencies
None code-wise. Schedule with the Zigbee key rotation window (task 13)?
**No** — do them separately; two auth changes at once doubles the debugging
surface when a device misbehaves.

## Risks
Medium (operational): a missed client loses the bus silently. Mitigation:
`docker logs mqtt` shows denied CONNECTs by IP — chase each until quiet.

## Estimated complexity
Small code, medium operations (~8k tokens + a 30-minute window).

## Suggested order
Hygiene phase; any time after the backup-phase tasks. Needs the operator
present (device verification), so flag it as not-fully-agent-executable.
