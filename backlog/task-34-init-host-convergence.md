# Task 34 — Make `init` converge the host (disposable-OS gap)

## Objective
On a fresh Debian 13 Lite image, `curl | bash` + `sudo domum-core init`
should produce a fully converged host with no hand-editing of system files.
Today several host-level settings exist only as manual steps in
`docs/getting-started/install.md` — that is preserved-by-hand OS state, which
contradicts the "OS is disposable" principle.

## Background — the current manual/host-state inventory
`init_host()` today: installs Docker, creates dirs, copies example configs.
Everything else is manual per install.md:

| Host state | Today | Rebuild risk if forgotten |
|---|---|---|
| `/etc/docker/daemon.json` log limits | manual | unbounded container logs slowly fill the NVMe — the classic Pi slow-death; also silently absent after every rebuild |
| apt packages: `restic age jq smartmontools` | manual / on-demand (`age` auto-installs inside recovery-pack create; restic checked at backup time) | first backup or DR step fails with "not installed" mid-procedure |
| sshd hardening, ufw, fail2ban | manual | security posture silently weaker after rebuild |
| timezone (compose hardcodes `TZ=America/New_York`, host TZ separate) | manual | log timestamps skew |
| systemd maintenance timers enablement | manual (`schedule install-maintenance` + explicit enables) | backups silently not running after rebuild (biggest one — task 33 records the enabled set, task 22 replays it) |

## Design decision — converge the mechanical, checklist the judgmental
Automate only what is deterministic and cannot lock the operator out:

**`init` converges (idempotent, additive, never overwrites divergent state):**
1. **Package list**: `apt-get install -y --no-install-recommends restic age
   jq smartmontools` (one short list, defined once near the top of the
   script; doctor's required-binary list must reference the same set —
   single source of truth).
2. **daemon.json**: if `/etc/docker/daemon.json` is absent → write the
   log-limits config (json-file, 10m×3) and restart Docker **only with
   confirm()** (restarting dockerd restarts every container — on first
   install that is free; on a live host the prompt protects). If the file
   exists but differs → print the expected content and a diff, change
   nothing. Never merge JSON in bash.
3. **Checkup additions** (the enforcement loop): warn when daemon.json log
   limits are missing; warn when any of the package list is missing. This
   converts "manual step forgotten" into a visible finding forever.

**`init` prints (never executes) — the judgment checklist:**
sshd hardening, ufw (with the Docker-bypasses-ufw caveat), fail2ban,
timezone (`timedatectl set-timezone`), and the timer-enable commands. These
involve security judgment or lockout risk (an automated sshd/ufw change on a
headless box can strand you); a printed 6-line checklist at the end of init
is the boring, safe form. install.md (task 27) becomes mostly "run init and
follow what it prints".

**Explicitly rejected:** any configuration-management tool, templating, or
`init --apply-security` automation of ssh/ufw. Also rejected: managing
`config.txt`/EEPROM from init (belongs in the storage/hardware runbooks —
touched once per hardware event, not per rebuild... EEPROM boot order does
need setting on a replacement Pi; that stays in task 26's runbook where the
operator is already physically present).

## Affected files
- `bin/domum-core` — `init_host()`, `run_checkup()` (2 findings),
  `doctor_cmd()` (share the package list)
- `docs/getting-started/install.md` (shrink accordingly — coordinate with
  task 27; if 27 lands first, it leaves a placeholder section "converged by
  init")
- `docs/backups/disaster-recovery.md` (step 1 note: init now handles
  packages/daemon.json — coordinate with tasks 22/26)

## Testing plan
- Fresh container/VM with bare Debian: run install.sh + `domum-core init` →
  packages present, daemon.json written, checklist printed; re-run init →
  no changes, no prompts (idempotence is the acceptance test).
- On the production Pi: run init → **must be a no-op except possibly the
  package install**; daemon.json already exists there (verify: if it matches
  the expected content, silence; if it differs, diff prints and nothing
  changes).
- `checkup` shows the two new findings when artificially unmet (rename
  daemon.json in a container test).

## Rollback strategy
Revert the commit. Host-side: daemon.json only ever created-if-absent —
remove it and restart Docker to return to defaults; packages are standard
Debian and harmless to keep.

## Dependencies
None hard. Complements 22 (wizard replays timers), 27 (install.md shrinks),
33 (timer state recorded). Do after the Phase 1 recovery core.

## Risks
Low-medium: the Docker restart on first-time daemon.json creation — gated by
confirm() and a warning that all containers restart. Everything else is
additive.

## Estimated complexity
Small–medium (~8k tokens).

## Suggested order
Phase 1 tail (after 21/26/22/23) or Phase 2 — before the next real rebuild,
ideally proven in the task-23 fire drill.
