# Annual Recovery Fire Drill

Automated restore verification proves selected backup bytes restore and pass
structural checks. Once a year, prove the full recovery process and the human
runbook on spare hardware or a VM.

Do not run this on the production Pi.

## Goal

Build a temporary domum-core host from scratch, restore from Hetzner or another
enabled target, and confirm the important apps open without touching the live
radios or production DNS.

## Procedure

1. Prepare a spare microSD, USB SSD, spare Pi, or VM.
2. Leave Zigbee and Z-Wave radios unplugged.
3. Keep Traefik/DNS pointed away from production names.
4. Follow [Disaster recovery](disaster-recovery.md): fresh Debian, installer,
   `sudo domum-core init`, then `sudo domum-core restore`.
5. Restore from the offsite target at least every other drill; Hetzner is the
   recovery path that matters when the house hardware is gone.
6. Verify Home Assistant UI loads with dashboards and integrations visible.
7. Verify Actual Budget opens a budget.
8. Verify `sudo domum-core checkup` has no unexpected criticals for the restored
   host. Radio and DNS findings are expected if those pieces were intentionally
   left disconnected.
9. Record date, target, duration, and any runbook fixes below.

## Log

| Date | Target | Duration | Result / fixes |
|---|---|---|---|
| _YYYY-MM-DD_ | _hetzner/local_ | _hh:mm_ | _notes_ |
