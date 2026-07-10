# domum-core — Improvement Backlog

Tasks 01–18: full repository audit, 2026-07-06.
Tasks 19–31 + reprioritization: reliability / recovery / architecture audit,
2026-07-09 (post-NVMe-migration).
Tasks 32–34 + amendments to 22/23/26: round-2 feedback, 2026-07-09
(disposable-OS review, principles doc, backup metadata, deeper restore
validation). Every task is sized for one independent AI-agent session:
self-contained context, clear success criteria, dry-run and rollback notes.

Sibling repo: `domum-core-media`. The two repos stay separate forever; tasks
marked **[shared-philosophy]** move this repo toward the common engineering
foundation, without merging anything.

## Roadmap — work the phases in order

### Phase 0 — Correctness & trust (trivial fixes, do as one batch)

| # | Task | Status | Complexity | Risk |
|---|------|--------|-----------|------|
| 01 | [Untrack the live config/domum.conf](task-01-untrack-live-config.md) | ✅ done (42e4d10) | trivial | low |
| 02 | [Fix install.sh repo URL and duplicate shim](task-02-fix-installer-repo-url-and-shim.md) | ✅ done (ac036c9) | trivial | low |
| 03 | [Fix --force delay-window bypass bug](task-03-fix-force-flag-bug.md) | ✅ done (b49327b) | trivial | low |
| 19 | [Make install.sh non-destructive (rm -rf landmine)](task-19-install-sh-nondestructive.md) | ✅ done (6a02978) | trivial | low |
| 20 | [Keep installed CLI/units in sync with the repo](task-20-installed-cli-stays-in-sync.md) | ✅ done (6ac428a) — on the Pi: re-run install.sh once to swap copies for symlinks | small | low |
| 04 | [Add missing BACKUP_MUSICASSISTANT default](task-04-musicassistant-backup-default.md) | ✅ done (d75232e) — verify on Pi: `backups run --dry-run` shows a musicassistant line | trivial | low |
| 32 | [Architecture principles + acceptance checklist doc](task-32-architecture-principles-doc.md) | ✅ done (53b7704) | small | none |

Rationale: 19 removes the one line that can destroy a restore; 20 makes every
later fix actually reach the production host (note: the 03 fix is live in git
but the Pi runs the installed copy until install.sh is re-run — exactly the
gap task 20 closes). 32 last in this phase: write the constitution before the
big recovery work is built against it.

### Phase 1 — Backup & recovery (the mission of this audit)

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 21 | [Backup pipeline correctness (isolation, source set, SQLite)](task-21-backup-pipeline-correctness.md) ✅ done (c401be7) — host steps remain: `backups run --dry-run` path review, simulated target failure, restore spot-check (see task's testing plan) | medium | medium |
| 33 | [Structured backup manifest (metadata)](task-33-backup-manifest-metadata.md) ✅ done (e6090de) — host check: `jq .` the manifest after next `backups run`; `restic dump latest` it | small-med | low |
| 26 | [Recovery docs overhaul + storage-replacement runbook](task-26-recovery-docs-overhaul.md) ✅ done (31b047f; A1 in 8c610f0) | medium | none |
| 22 | [Guided restore: `domum-core restore`](task-22-guided-restore-command.md) ✅ done (870b951) — sandbox-verified end-to-end (real restic/age/rsync); on the Pi run read-only steps 1–2 only; full drill is task 23's rehearsal | large | medium |
| 23 | [Automated restore verification (monthly) + annual fire drill](task-23-restore-verification.md) | medium | low |
| 24 | [Multi-destination backups: Buffalo/Unraid/USB](task-24-multi-destination-backups.md) | medium | low-med |
| 34 | [Make `init` converge the host (disposable OS)](task-34-init-host-convergence.md) | small-med | low-med |

Note: the wrong restic `--target` command in disaster-recovery.md (task 26,
item A1) was cherry-picked ahead of the rest of 26 — ✅ done (8c610f0).
Items A2–D of task 26 remain open.

### Phase 2 — Visibility

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 25 | [Weekly health report email](task-25-weekly-health-report.md) | medium | low |
| 28 | [Checkup: USB radio device presence](task-28-checkup-usb-radio-presence.md) | small | low |
| 05 | [Fix stale documentation references](task-05-stale-doc-references.md) — ✅ done (a3ffbb4); remember `schedule install-maintenance` on the Pi to refresh installed units | small | none |

### Phase 3 — Update model hardening

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 09 | [Warn on pending update candidates during apply](task-09-apply-warns-on-candidates.md) | small | low |
| 31 | [Apply exactly the aged candidate + `updates rollback`](task-31-updates-apply-race-and-rollback.md) | medium | medium |
| 10 | [Pin critical stateful images (MariaDB, HA, Traefik-major)](task-10-pin-critical-images.md) | medium | medium |

### Phase 4 — Hygiene & simplification

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 06 | [Night profile: delete, or rebuild on the catalog](task-06-night-profile-from-catalog.md) | medium | medium |
| 07 | [CI cleanup and alignment with sibling](task-07-ci-cleanup.md) **[shared-philosophy]** | small | low |
| 08 | [Catalog-consistency smoke tests](task-08-catalog-smoke-tests.md) **[shared-philosophy]** | medium | low |
| 30 | [Compose + gitignore hygiene batch](task-30-compose-hygiene.md) | small-med | low-med |
| 27 | [Rewrite install doc for NVMe / Debian 13](task-27-install-doc-rewrite.md) | small-med | none |
| 12 | [Remove tracked traefik usersfile placeholder](task-12-remove-usersfile.md) | trivial | low |
| 14 | [Docs index completeness pass](task-14-docs-index.md) | trivial | none |
| 15 | [Unified logging convention](task-15-logging-convention.md) **[shared-philosophy]** | small | low |
| 16 | [Git workflow conventions doc](task-16-git-conventions.md) **[shared-philosophy]** | small | none |

### Phase 5 — Needs the operator (host access / maintenance window)

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 29 | [MQTT authentication (anonymous LAN broker)](task-29-mqtt-authentication.md) | small code / medium ops | medium |
| 11 | [Remove or justify iot_vlan50 in ensure_networks](task-11-iot-vlan50.md) | small | medium |
| 13 | [Zigbee network key rotation runbook](task-13-zigbee-key-rotation.md) | small (doc) | medium (op) |

### Phase 6 — Future ideas (do not start without a fresh decision)

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 17 | [Relocate runtime data out of the git tree](task-17-data-out-of-git-tree.md) **[shared-philosophy]** | large | high |
| 18 | [Namespace config keys with DOMUM_ prefix](task-18-namespace-config-keys.md) **[shared-philosophy]** | medium | medium |

## Audit conclusions worth remembering (2026-07-09)

- **USB radios are already port-independent** (`/dev/serial/by-id`). Decision:
  no udev rules — see task 28 for the recorded rationale.
- **The update-candidate model stays.** It has bugs (03, 09, 31) but the
  architecture is sound and right-sized; rearchitecting to pure pins was
  considered and rejected — fix, don't rewrite.
- **Four backup destinations ≠ four nightly pushes.** See task 24's Option A:
  Hetzner + one NAS nightly from the Pi, second NAS replicates NAS-side,
  USB on demand.
- **Recovery-pack + restic is the right two-piece DR design.** The wizard
  (task 22) orchestrates the existing pieces; it does not add new storage or
  discovery machinery.

## Disposable-OS review (round 2, 2026-07-09)

Governing principle: **recovery = fresh Debian image + bootstrap + restore;
never preserve or transplant an old root filesystem.** Backlog reviewed
against it:

- Aligned already: 19 (install-before-restore ordering), 22 (fresh-Pi flow),
  the recovery-pack design, 20 (symlinks are host state, but bootstrap
  recreates them).
- Flagged and fixed in the tasks:
  - Task 26's storage-replacement runbook was clone-shaped → reframed:
    cloning is a convenience for *planned* swaps only; rebuild is the
    recovery path (amendment in task 26).
  - Manual host steps (daemon.json, apt packages) were hand-preserved OS
    state → task 34 makes `init` converge the mechanical parts; the
    judgment parts (sshd/ufw/fail2ban) stay a printed checklist by design.
  - Systemd timer enablement was invisible host state lost on rebuild →
    recorded in the backup manifest (task 33), replayed by the wizard
    (task 22 step 7).
  - Tailscale state is intentionally not backed up → declared as designed
    loss with a re-auth note (task 26 item D2).
- The hard floor no design can remove: the **AGE private key** and (for the
  wizard's manual path) a **restic password** must survive off-Pi. One
  password-manager entry + one printed copy. Everything else is
  reconstructable.

## For implementing agents

Tasks in this backlog are executed by different AI models in fresh sessions
(opencode / Codex / Claude Code — assume no shared context and no memory of
the conversations that produced these tasks). **Read [/AGENTS.md](../AGENTS.md)
first** — it is the execution contract: prime directives, scope discipline,
verification commands, and the stop-and-ask conditions. Every task file is
deliberately self-contained; if one isn't, that is a bug — fix the task file
in the same session.

## Ground rules for every task

The design philosophy and per-change acceptance checklist live in
[docs/reference/architecture-principles.md](../docs/reference/architecture-principles.md).
Backlog-specific rules on top of it:

- Every change must pass CI: `bash -n bin/domum-core`, `shellcheck bin/*`,
  yamllint, `docker compose ... config -q` (see
  `.github/workflows/validate.yml`).
- Tasks are independent unless the **Dependencies** section says otherwise.
- After merging anything in `bin/` or `systemd/`, deploy on the host with
  `sudo domum-core update` (binaries are symlinks and installed units refresh
  automatically since task 20; hosts installed before task 20 must re-run
  `install.sh` once).
