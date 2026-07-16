# Zigbee Network Key Rotation

This runbook is for a planned Zigbee2MQTT network-key rotation. Do not run it as
routine maintenance and do not let an agent perform it unattended. Changing the
Zigbee network key is disruptive: expect to re-pair every Zigbee device.

Why this exists: an old Zigbee network key was committed to git history before
`compose/automation/zigbee2mqtt/configuration.yaml` was changed to use
`'!secret network_key'`. The current live key lives in the ignored file
`/opt/domum-core/compose/automation/zigbee2mqtt/secret.yaml`, but historical repo
access may have exposed the old key. Rotate during a maintenance window.

Decision: do not rewrite git history. Once the live Zigbee mesh uses a new key,
the historical key is obsolete for this home. History rewriting would add more
operational risk than value for this repository.

## When To Rotate

Rotate only when you can tolerate Zigbee downtime and device re-pairing.

Plan roughly:

- 15-30 minutes for backup, editing, and coordinator restart.
- 5-10 minutes per mains-powered router device.
- 5-15 minutes per sleepy battery device, depending on reset procedure.
- Extra time to rename devices and confirm Home Assistant entities.

Do not combine this with Zigbee2MQTT upgrades, coordinator firmware updates,
radio replacement, or Home Assistant upgrades.

## Pre-Flight

Confirm the current tracked config uses secret indirection:

```bash
grep -n "network_key" /opt/domum-core/compose/automation/zigbee2mqtt/configuration.yaml
```

Expected:

```yaml
network_key: '!secret network_key'
```

Confirm the live secret file exists and is ignored by git:

```bash
sudo test -f /opt/domum-core/compose/automation/zigbee2mqtt/secret.yaml
git -C /opt/domum-core check-ignore compose/automation/zigbee2mqtt/secret.yaml
```

Record the current device list for re-pair planning:

```bash
docker logs zigbee2mqtt --since 10m | grep -E 'Currently .* devices are joined|\(0x[0-9a-f]+\):' || true
```

Take a fresh backup:

```bash
sudo domum-core backups run
sudo domum-core checkup
```

Make a local rollback copy of the current Zigbee2MQTT config/state. This copy is
for the maintenance window only; do not commit it.

```bash
ts="$(date +%Y%m%d-%H%M%S)"
sudo tar -C /opt/domum-core/compose/automation \
  -czf "/var/lib/domum-core/service-backups/zigbee2mqtt-pre-key-rotation-${ts}.tar.gz" \
  zigbee2mqtt
sudo chmod 600 "/var/lib/domum-core/service-backups/zigbee2mqtt-pre-key-rotation-${ts}.tar.gz"
```

## Generate New Values

Generate a new 16-byte Zigbee network key in Zigbee2MQTT's YAML array format:

```bash
python3 - <<'PY'
import secrets
print("network_key: [" + ", ".join(str(secrets.randbelow(256)) for _ in range(16)) + "]")
PY
```

Generate new PAN IDs. Changing them avoids devices trying to reuse stale network
state.

```bash
python3 - <<'PY'
import secrets
pan = secrets.randbelow(0xFFFE - 1) + 1
ext = ", ".join(f"0x{secrets.randbelow(256):02x}" for _ in range(8))
print(f"pan_id: 0x{pan:04x}")
print(f"ext_pan_id: [{ext}]")
PY
```

Avoid `0x0000`, `0xffff`, and values already used by nearby known Zigbee
networks if you track them.

## Apply The New Key

Stop only Zigbee2MQTT:

```bash
docker stop zigbee2mqtt
```

Edit the ignored live secret file:

```bash
sudoedit /opt/domum-core/compose/automation/zigbee2mqtt/secret.yaml
```

Update or add these keys using the generated values:

```yaml
network_key: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
pan_id: 0x1234
ext_pan_id: [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]
```

Keep existing MQTT credentials in the same file:

```yaml
mqtt_user: "domum"
mqtt_pass: "..."
```

Start Zigbee2MQTT:

```bash
docker start zigbee2mqtt
docker logs zigbee2mqtt --since 2m
```

Expected at this point: Zigbee2MQTT starts, but existing devices are not joined
to the new network yet.

## Re-Pair Devices

Open the Zigbee2MQTT UI and enable permit join only while actively pairing:

```text
https://z2m.<your-domain>
```

Pair mains-powered routers first, then battery devices. For each device:

1. Factory reset the device using the vendor procedure.
2. Wait for it to join in Zigbee2MQTT.
3. Give it the intended friendly name if needed.
4. Confirm it publishes state to MQTT.
5. Confirm Home Assistant sees the entity and automations still reference the
   expected entity names.

Turn permit join off when done.

## Verify

```bash
docker logs zigbee2mqtt --since 10m
sudo domum-core checkup
git -C /opt/domum-core status --short
```

Expected:

- Zigbee2MQTT is running.
- MQTT is reachable.
- Devices report in Zigbee2MQTT and Home Assistant.
- `git status --short` is clean; runtime files remain ignored.

Run a fresh backup after the new mesh is stable:

```bash
sudo domum-core backups run
```

## Rollback During The Window

Rollback only makes sense before you have committed to re-pairing everything. It
restores the previous Zigbee2MQTT state and old key.

```bash
docker stop zigbee2mqtt
sudo tar -C /opt/domum-core/compose/automation -xzf \
  /var/lib/domum-core/service-backups/zigbee2mqtt-pre-key-rotation-YYYYMMDD-HHMMSS.tar.gz
docker start zigbee2mqtt
docker logs zigbee2mqtt --since 2m
sudo domum-core checkup
```

If you already re-paired devices onto the new key, rolling back means those
devices must be reset and paired back to the old network.

## After Successful Rotation

After every needed device is stable on the new key:

1. Remove the historical Zigbee key allowlist from `.gitleaks.toml`.
2. Run the full validation suite.
3. If gitleaks still flags old commits, decide explicitly whether to keep a
   narrower history-only allowlist or accept the finding as resolved by
   rotation.
4. Do not rewrite git history.

The plaintext old key remains in git history, but it no longer protects the live
Zigbee network.
