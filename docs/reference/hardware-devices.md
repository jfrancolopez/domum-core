# Hardware devices on Raspberry Pi (USB / serial) and Docker Compose

If a device is missing, Docker Compose will fail with errors like:

- `error gathering device information while adding custom device "/dev/ttyUSB0": no such file or directory`

This doc shows how to identify attached devices and how to make services optional per-host so deploys do not break.

---

## 1) Quick device discovery

### 1.1 See what USB devices are connected

```bash
lsusb
```

Useful when you just want to confirm the dongle is detected at all.

### 1.2 See serial devices (ttyUSB / ttyACM)

```bash
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true
```

Common outcomes:

- Many Zigbee dongles: `/dev/ttyUSB0`
- Many newer dongles (CDC ACM): `/dev/ttyACM0`

### 1.3 Prefer stable device names using `/dev/serial/by-id` (recommended)

The safest way is to use the `by-id` symlink, because `/dev/ttyUSB0` can change after reboots.

```bash
ls -l /dev/serial/by-id 2>/dev/null || true
```

Example output may look like:

- `/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_... -> ../../ttyACM0`

Use the full `/dev/serial/by-id/...` path whenever possible.

### 1.4 When the device is not showing up

Check kernel logs and udev:

```bash
dmesg | tail -n 200
udevadm monitor --udev
```

Plug/unplug the device while `udevadm monitor --udev` is running and you will see the events.

---

## 2) Identify a device with details (vendor, model, path)

### 2.1 Map a tty device to its udev properties

Replace `ttyACM0` or `ttyUSB0` with what you actually have:

```bash
udevadm info -a -n /dev/ttyACM0 | head -n 80
```

You can use this to confirm manufacturer/product strings.

### 2.2 Verify the stable `by-id` link points to the expected tty device

```bash
readlink -f /dev/serial/by-id/* 2>/dev/null || true
```

---

## 3) How device paths should be used in Compose

### 3.1 Use `/dev/serial/by-id` whenever possible

This is the most stable option, especially on a Pi where USB enumeration can change.

Bad (fragile):

- `/dev/ttyUSB0`

Good (stable):

- `/dev/serial/by-id/usb-<something-readable>`

### 3.2 Example: Zigbee2MQTT

If your Zigbee dongle exists on this host:

1) Discover the path:

```bash
ls -l /dev/serial/by-id
```

2) In Zigbee2MQTT configuration, set:

```yaml
serial:
  port: /dev/serial/by-id/usb-<your-dongle-id>
```

If you do device mapping in Compose, keep the host path stable:

```yaml
devices:
  - /dev/serial/by-id/usb-<your-dongle-id>:/dev/ttyACM0
```

Tip: many setups do not need the container-side name to match the host name.
What matters is the host path you pass in.

---

## 4) Prevent deploy failures when hardware is missing (per-host toggles)

If a service requires hardware, do not enable it globally for every host.
Instead, use a per-host flag so the service is only included where the device exists.

### 4.1 Pattern: `HAS_*` flags

Add a host capability flag to `config/domum.conf`, for example:

```bash
# Hardware capability flags (host-specific)
HAS_ZIGBEE_DONGLE=0
```

On the host that actually has the dongle plugged in:

```bash
HAS_ZIGBEE_DONGLE=1
```

### 4.2 Gate the service in `bin/domum`

In `compose_files_for_enabled_services()`, include the service only when both:
- the service is enabled, and
- the host capability is true

Example for Zigbee2MQTT:

```bash
if [[ "${ENABLE_ZIGBEE2MQTT:-0}" == "1" && "${HAS_ZIGBEE_DONGLE:-0}" == "1" ]]; then
  files+=("$DOMUM_DIR/compose/automation/zigbee2mqtt.yml")
fi
```

Now you can keep:

```bash
ENABLE_ZIGBEE2MQTT=1
```

in your config defaults, but the service will only deploy on hosts that set:

```bash
HAS_ZIGBEE_DONGLE=1
```

### 4.3 Recommended workflow

1) On a new host, start with hardware flags off:

```bash
HAS_ZIGBEE_DONGLE=0
```

2) Deploy via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash
```

3) Plug in the device, confirm it exists:

```bash
ls -l /dev/serial/by-id
```

4) Flip the flag:

```bash
sudo nano /opt/domum-core/config/domum.conf
# set HAS_ZIGBEE_DONGLE=1
```

5) Re-run deploy:

```bash
curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash
```

---

## 5) Troubleshooting checklist

### 5.1 Docker says the device path does not exist

- Confirm the dongle is plugged in.
- Confirm it shows up:

```bash
lsusb
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true
ls -l /dev/serial/by-id 2>/dev/null || true
```

- If it does not show, check:

```bash
dmesg | tail -n 200
```

### 5.2 Device exists but Zigbee2MQTT still cannot open it

This is usually permissions/groups.
Common fixes:

- Ensure the container runs with access to the device (compose `devices:` mapping).
- Ensure the host user/group settings are correct (often `dialout` group for serial devices).
- Prefer running the service as root inside the container if needed, then tighten later.

### 5.3 You moved the dongle to a different USB port and the name changed

That is exactly why `/dev/serial/by-id` is recommended.
Use the by-id path and the issue goes away.



