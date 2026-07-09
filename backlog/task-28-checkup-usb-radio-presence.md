# Task 28 — Checkup: verify USB radio device presence (and close the USB audit)

## Objective
Add the one missing piece of USB-device reliability: `checkup` should say
"the Zigbee dongle is missing" *before* the operator discovers it via dead
automations or a compose failure.

## Background — USB audit conclusion (record this so it isn't re-litigated)
The audited concern was "containers depend too much on physical USB port
placement." Verified: **they do not.** Both radios are already mapped via
serial-descriptor-stable paths:
- zigbee2mqtt: `/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_1069b4aa...-if00-port0`
  → `/dev/serial/by-id/sonoff-zigbee` in-container (and z2m's
  `configuration.yaml` points at the stable in-container name — good design:
  app config never changes even if the dongle does).
- zwave-js-ui: `/dev/serial/by-id/usb-0658_0200-if00` → `/dev/zwave`.

`/dev/serial/by-id/*` is generated from USB vendor/product/serial descriptors:
**moving a dongle to another physical port never changes it.** It changes only
when the dongle hardware itself is replaced.

**Decision: do NOT add udev rules.** A udev rule (`/dev/zigbee` symlink by
vendor/serial) would abstract dongle replacement, but: it is host state
outside git unless install.sh manages it, it is one more thing to restore in
DR, and the event it optimizes (replacing a radio) happens ~once per five
years and already requires re-pairing work orders of magnitude larger than
editing one compose line. The compose device line stays the single source of
truth. (Documented trade-off; revisit only if radios start churning.)

Residual gaps this task closes:
1. If a dongle is unplugged/dead, `docker compose up` fails for that service
   with an obscure "error gathering device information" — and `checkup`
   currently says only "container not running".
2. `docs/reference/hardware-devices.md` is good but doesn't state the
   port-independence conclusion or the replacement procedure crisply.

## Implementation plan
1. **Catalog-driven device check.** Add an optional 8th column `device` to
   `service_catalog()` (`-` for none), holding the host device path:
   - `zigbee2mqtt` → the sonoff by-id path
   - `zwave-js-ui` → the 0658 by-id path
   Wait — the path is per-host hardware, and the catalog is git-tracked.
   Simpler and better: **derive it from the compose file at runtime**. In
   `run_checkup()`:
   ```bash
   # for each enabled service, grep its compose file for host device paths
   awk '/^\s*devices:/{f=1;next} f&&/^\s*-\s*\//{print $2} f&&!/^\s*-/{f=0}' <compose_file>
   ```
   then for each `host_path` (the part before the colon):
   `[[ -e $host_path ]] || checkup_add critical "<svc>: USB device missing: $host_path"`.
   No new config, no catalog column, zero maintenance when devices change —
   the compose file remains the single source of truth. Keep the awk
   tolerant; on parse failure, silently check nothing (best-effort probe).
2. Success path: `checkup_add healthy "<svc> USB device present ($basename)"`.
3. **Docs:** add a short section to `docs/reference/hardware-devices.md`:
   - "Port moves never require config changes (by-id explained)".
   - "Replacing a radio: the one line to edit" — compose device path; plus
     the z2m/zwave app-level notes (z2m in-container path unchanged; Z-Wave
     requires the same-or-restored NVM for the network to survive — link
     zwave-js-ui NVM backup feature; note z2m `coordinator_backup.json`).
4. Cross-link from disaster-recovery.md's radio note (task 26 wording).

## Affected files
- `bin/domum-core` (`run_checkup` — ~15 lines)
- `docs/reference/hardware-devices.md`
- `docs/backups/disaster-recovery.md` (one link; coordinate with task 26)

## Testing plan
- Host: `sudo domum-core checkup` → two healthy lines for the radios.
- Unplug test (maintenance moment) or temporarily edit a compose copy to a
  bogus path with `CFG_FILE`/`DOMUM_DIR` overrides → critical line appears.
- shellcheck + `bash -n` pass; the awk handles both radios' compose formats.

## Rollback strategy
Revert — read-only checkup lines, no behavior change anywhere else.

## Dependencies
None.

## Risks
Low. False criticals only if the awk misparses; guard by matching strictly
`- /dev/...:` list items.

## Estimated complexity
Small (~6k tokens).

## Suggested order
Anytime; cheap reliability win — good filler task between larger phases.
