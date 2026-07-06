# Task 11 — Remove or justify `iot_vlan50` in ensure_networks

## Objective
Stop `ensure_networks()` from silently creating a plain bridge network named
`iot_vlan50` that no compose file references — or document why it must exist.

## Files involved
- `bin/domum-core` — `ensure_networks()` (~line 437)
- Possibly `docs/reference/dns.md` / `docs/reference/hardware-devices.md`
  (wherever the VLAN story lives)

## Reason
`ensure_networks` creates `domum-internal`, `domum-proxy`, `domum-data`
(all defined in `compose/base.yml`) **plus** `iot_vlan50`, which appears in
no compose file in the repo. Git history ("bin: create iot_vlan50") suggests
it was a macvlan for the IoT VLAN era. Two problems:
1. If the network was manually created as a macvlan on the Pi and ever gets
   deleted, this code recreates it as a **default bridge** with the same
   name — worse than absent, because attached services would get wrong
   networking that looks configured.
2. If nothing uses it anymore, it is dead code that misleads readers.

## Implementation plan
1. On the Pi: `docker network inspect iot_vlan50` — record driver and which
   containers (if any) are attached.
2. If unused: remove it from `ensure_networks()`; note in the commit message
   that the host-side network object can be removed manually
   (`docker network rm iot_vlan50`) once confirmed unattached. Do not remove
   it from the host automatically.
3. If used (e.g. HA attached manually for mDNS/VLAN reach): keep it, but
   replace blind creation with a check-and-warn:
   missing → `warn "iot_vlan50 missing — create it manually as macvlan (see docs/...)"`,
   never auto-create. Add the macvlan creation command to docs.

## Testing plan
- `sudo domum-core apply` on the host: no error, no unexpected new network.
- `docker network ls` matches expectations before/after.

## Risk
Medium only if step 1 is skipped — the network may be load-bearing for HA
device discovery. The investigation *is* the task; the code change is small.

## Rollback
Revert; `apply` recreates the old behavior.

## Dependencies
None. Requires SSH access to the Pi for step 1 (agent should stop and ask
for the inspect output if it cannot reach the host).

## Estimated complexity / token size
Small (~5k tokens) + one host command.

## Suggested order
11.
