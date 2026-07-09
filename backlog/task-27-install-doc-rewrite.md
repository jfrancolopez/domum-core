# Task 27 — Rewrite the install doc for the real platform (NVMe, Debian 13)

## Objective
`docs/getting-started/install.md` should describe the machine that actually
exists (Pi 5, Debian 13 Lite, native NVMe boot via the official PCIe HAT) and
nothing else. Today it is a historical braindump that would misdirect a
rebuild.

## Verified problems in the current doc
- Titled "SSD Boot": sections 0.1–0.3 cover **USB** boot enablement,
  `usb_max_current_enable`, `BOOT_ORDER=0xf41` — the pre-incident setup. The
  production host boots from **NVMe** (different EEPROM boot order, no USB
  current tweak).
- Section 6 documents an **rsync-mirror + cron backup strategy to
  `/home/jfranco/backups`** that predates and now contradicts the restic
  system (`docs/backups/overview.md`). Two contradictory backup docs is worse
  than one — a rebuilder might follow the wrong one.
- Personal-specific content baked in: username `jfranco`, `ladomum.com`
  Cockpit origins, HACS-for-**Frigate** instructions (Frigate was removed
  from this host — see removed-services.md).
- Useful content is buried and unordered: the Traefik htpasswd block, the HA
  first-run `secrets.yaml` requirement, Docker log limits, ufw rules —
  these are real and must survive the rewrite.

## Desired shape (rewrite, keep it short)
```
docs/getting-started/install.md
1. Hardware assumptions (Pi 5, PCIe HAT, NVMe, radios)
2. Flash Debian 13 Lite (Raspberry Pi Imager; headless ssh enablement)
3. EEPROM: NVMe boot order (rpi-eeprom-config, the actual value used)
4. Base OS: apt full-upgrade, hostname, timezone
5. Security baseline: sshd hardening, ufw (with the REAL rule list incl. the
   Docker-bypasses-ufw caveat), fail2ban
6. Docker: official repo install (or just "run install.sh — it installs
   Docker"; do not duplicate what init_host does — link it)
7. Docker daemon log limits (daemon.json)
8. curl | bash install.sh → configure → init → apply (link first-run.md)
9. Host-specific one-offs: Traefik dashboard htpasswd, HA secrets.yaml
   first-run requirement (or move that to services/home-assistant.md),
   Cockpit reverse-proxy note (genericized)
```
Delete outright: USB-boot sections (superseded — storage-replacement runbook
from task 26 owns boot-media topics), the rsync/cron backup strategy
(superseded by restic; add one line "backups: see docs/backups/overview.md"),
HACS/Frigate instructions (wrong host; if HACS matters for HA generally, one
genericized paragraph belongs in services/home-assistant.md), sudo-group
remediation for a named user (genericize to `$USER` in one short appendix or
drop).

## Consistency rules for the rewrite
- No personal usernames/domains — use `$USER` / `example.com` placeholders
  (the live values belong in the untracked live config, per repo philosophy).
- Every section either contains runnable commands or links to the doc that
  does. No narrative history.
- Note near the ufw block: Docker-published ports bypass ufw (relevant to
  MQTT 1883 — cross-link task 29).

## Affected files
- `docs/getting-started/install.md` (rewrite)
- `docs/services/home-assistant.md` (receives HA first-run secrets note if
  moved)
- `docs/README.md` (no change expected; verify link text)

## Testing plan
- Dry-read as a from-scratch rebuild alongside disaster-recovery.md — the
  two must not contradict each other on any step.
- `grep -n 'jfranco\|frigate\|HACS\|usb_max_current\|rsync -aHAX' docs/getting-started/install.md`
  → only intentional hits remain (ideally zero).

## Rollback strategy
Docs only — revert. Old content stays in git history if a deleted nugget is
missed.

## Dependencies
Task 26 (storage-replacement runbook absorbs the boot-media content — do 26
first or together so nothing falls between the two docs).

## Risks
None operational. Main risk is deleting a still-needed nugget — mitigated by
the explicit "survivor list" above (htpasswd, HA secrets.yaml, daemon.json,
ufw, fail2ban).

## Estimated complexity
Small–medium (~10k tokens).

## Suggested order
Documentation phase, after task 26.
