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
| 37 | [CRITICAL: configure wizard stdin bug — silently disables services](task-37-configure-wizard-stdin-bug.md) | ✅ done (d6ac801) | small | low |

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
| 23 | [Automated restore verification (monthly) + annual fire drill](task-23-restore-verification.md) ✅ done (4cd9f08; Hetzner restore-verify host-validated 2026-07-16) | medium | low |
| 39 | [App-consistent offsite service archives for database-style apps](task-39-app-consistent-offsite-service-archives.md) ✅ done (d9928eb; Hetzner snapshot 28831507 restore-verified 2026-07-16) | medium | medium |
| 24 | [Multi-destination backups: Buffalo/Unraid/USB](task-24-multi-destination-backups.md) ✅ code/docs done (6f81552, 6f9322c) — host acceptance remains: configure/initialize LAN NAS target if desired and test `backups usb <mount>` on a scratch mounted disk | medium | low-med |
| 34 | [Make `init` converge the host (disposable OS)](task-34-init-host-convergence.md) ✅ done (04fdd2b; host-validated 2026-07-16) | small-med | low-med |

Note: the wrong restic `--target` command in disaster-recovery.md (task 26,
item A1) was cherry-picked ahead of the rest of 26 — ✅ done (8c610f0).
Items A2–D of task 26 remain open.

### Phase 2 — Visibility

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 25 | [Weekly health report email](task-25-weekly-health-report.md) ✅ done (6f97eb6; real email sent and timer enabled 2026-07-16) | medium | low |
| 41 | [Weekly report: retro HTML email + mobile text](task-41-weekly-report-retro-html.md) ✅ code done (2a0d010, 2026-07-16); Pi send + mail-client check pending | small | low |
| 42 | [Weekly report: extra content sections](task-42-weekly-report-extra-sections.md) ✅ done 2026-07-16 (sparklines, NVMe, power; rot table resolved as redundant; Pi-verified) | small | low |
| 43 | [Weekly report: escalating attention colors](task-43-report-threshold-colors.md) ✅ done 2026-07-17 | small | low |
| 44 | [Weekly report: monthly/yearly averages](task-44-report-monthly-averages.md) ✅ done 2026-07-17 | small | low |
| 45 | [Weekly report: drive temperature average](task-45-report-drive-temp-average.md) ✅ done 2026-07-17 | small | low |
| 28 | [Checkup: USB radio device presence](task-28-checkup-usb-radio-presence.md) ✅ done (623377c) | small | low |
| 05 | [Fix stale documentation references](task-05-stale-doc-references.md) — ✅ done (a3ffbb4); remember `schedule install-maintenance` on the Pi to refresh installed units | small | none |

### Phase 3 — Update model hardening

**Priority raised (2026-07-10):** the predicted incident happened — `apply`
recreated mariadb onto a previously pulled `mariadb:latest` 12.3, which
crash-looped on the old datadir and took Home Assistant down until the image
was pinned back. Task 36 is the umbrella redesign (pull-free check,
digest-verified apply, scheduled apply-auto, tier policy, image-age
rot-nagging); it supersedes 31. Order: 10 (formalize the emergency pin) →
36 → 09 (now defense-in-depth).

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 10 | [Pin critical stateful images (MariaDB, HA, Traefik-major)](task-10-pin-critical-images.md) ✅ done (1e2cab1) | medium | medium |
| 36 | [Unattended-safe update pipeline](task-36-unattended-update-pipeline.md) ✅ code done (33e1f4b, a0e364a, da13621, 97a33df, 32dd589, 13a5f4f) — host rollback round-trip remains when an update history entry exists | med-large | medium |
| 09 | [Warn on pending update candidates during apply](task-09-apply-warns-on-candidates.md) ✅ done (519b5e1) | small | low |
| 46 | [Make security-apply dry-run use unattended-upgrades selection](task-46-security-apply-dry-run-selector.md) | trivial | low |
| ~~31~~ | [superseded by 36](task-31-updates-apply-race-and-rollback.md) | — | — |

### Phase 4 — Hygiene & simplification

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 06 | [Night profile: delete, or rebuild on the catalog](task-06-night-profile-from-catalog.md) ✅ done (bf8e59a) | medium | medium |
| 07 | [CI cleanup and alignment with sibling](task-07-ci-cleanup.md) ✅ done (3248b53) **[shared-philosophy]** | small | low |
| 08 | [Catalog-consistency smoke tests](task-08-catalog-smoke-tests.md) ✅ done (41bee61) **[shared-philosophy]** | medium | low |
| 30 | [Compose + gitignore hygiene batch](task-30-compose-hygiene.md) ✅ partial safe batch (pending: Traefik static config consolidation, HA privileged decision) | small-med | low-med |
| 38 | [Ignore ESPHome live config and secrets](task-38-ignore-esphome-live-config.md) | ✅ done (10edf9e) | trivial | low |
| 27 | [Rewrite install doc for NVMe / Debian 13](task-27-install-doc-rewrite.md) ✅ done (02b20e7) | small-med | none |
| 12 | [Remove tracked traefik usersfile placeholder](task-12-remove-usersfile.md) ✅ done (a644161) | trivial | low |
| 14 | [Docs index completeness pass](task-14-docs-index.md) ✅ done (46541bf) | trivial | none |
| 15 | [Unified logging convention](task-15-logging-convention.md) ✅ done (c7dd2d4) **[shared-philosophy]** | small | low |
| 16 | [Git workflow conventions doc](task-16-git-conventions.md) ✅ done (2eb93b3) **[shared-philosophy]** | small | none |
| 35 | [Update/install must not depend on operator SSH identity](task-35-anonymous-fetch-resilience.md) ✅ done (a60abad) | trivial-small | none |
| 40 | [Split runtime-written app config from tracked templates](task-40-split-runtime-written-config.md) ✅ done (7b38301, 6e4261d, 8382f98, 111a258) | small-med | medium |

### Phase 5 — Needs the operator (host access / maintenance window)

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 29 | [MQTT authentication (anonymous LAN broker)](task-29-mqtt-authentication.md) ✅ done (b932088) | small code / medium ops | medium |
| 11 | [Remove or justify iot_vlan50 in ensure_networks](task-11-iot-vlan50.md) ✅ code done (98efd81) — on the Pi: inspect/remove the old Docker network only if unattached | small | medium |
| 13 | [Zigbee network key rotation runbook](task-13-zigbee-key-rotation.md) ✅ runbook done (700ef03) — rotation + gitleaks allowlist removal remain operator follow-up | small (doc) | medium (op) |

### Phase 6 — Future ideas (do not start without a fresh decision)

| # | Task | Complexity | Risk |
|---|------|-----------|------|
| 17 | [Relocate runtime data out of the git tree](task-17-data-out-of-git-tree.md) **[shared-philosophy]** | large | high |
| 18 | [Namespace config keys with DOMUM_ prefix](task-18-namespace-config-keys.md) **[shared-philosophy]** | medium | medium |

## Glance daily-dashboard program

This is a separate, operator-approved program for turning Glance into the
private daily information dashboard while Homepage remains the service launcher
and fast operational portal. Read the [program charter](glance-dashboard-program.md)
before taking any Glance task. Work tasks in order unless their dependency
section explicitly permits otherwise. Each task is intentionally bounded to one
fresh AI-agent session and requires approval before the next page is started.

| Phase | # | Task | Status | Complexity | Risk |
|---|---:|---|---|---|---|
| 0 | 47 | [Audit live Glance and data sources](task-47-glance-live-audit.md) | ✅ report captured; final responsive/performance evidence pending | medium | low |
| 0 | 67 | [Remove unsafe uncommitted Glance implementation](task-67-glance-remediate-unsafe-worktree.md) | ✅ no uncommitted Glance draft remains in current checkout | small | low |
| 0 | 48 | [Define architecture, privacy, and capability matrix](task-48-glance-architecture-matrix.md) | ✅ architecture and matrix documented; per-source gates remain | medium | none |
| 0 | 68 | [Remediate committed unsafe Network draft](task-68-glance-remediate-committed-network-draft.md) | ✅ replaced by validated v0.8.5 Network configuration | small | low |
| 0 | 69 | [Add private CIDR plumbing for Glance access policy](task-69-glance-private-cidr-plumbing.md) | ✅ code done; Pi boundary evidence recorded in audit | small | low |
| 1 | 49 | [Enforce the private access boundary](task-49-glance-private-access.md) | ✅ policy and Pi path tests recorded; final browser/performance evidence pending | medium | medium |
| 1 | 50 | [Pin, validate, and plumb secrets](task-50-glance-runtime-foundation.md) | ✅ code done 2026-08-12; gitleaks unavailable locally | medium | low-med |
| 1 | 51 | [Build the modular visual foundation](task-51-glance-foundation.md) | ✅ foundation done 2026-08-12; visual prototype selection deferred to polish | medium | low |
| 2 | 52 | [Build the Home page](task-52-glance-home-page.md) | ✅ first native pass done 2026-08-12; private calendar deferred | medium | low |
| 3 | 53 | [Build core Hosting](task-53-glance-hosting-core.md) | ✅ core native pass done 2026-08-12; Beszel/backup/Healthchecks detail deferred | medium | low-med |
| 3 | 54 | [Add one external Hosting source](task-54-glance-hosting-external.md) | ✅ done | medium | medium |
| 3 | 55 | [Build core Network](task-55-glance-network-core.md) | ✅ code done; Pi data/failure validation and screenshots pending | medium | medium |
| 3 | 56 | [Add one deep Network source](task-56-glance-network-services.md) | ✅ AdGuard/UniFi code done; Pi credential/data/failure validation pending | medium | medium |
| 4 | 57 | [Build core Media](task-57-glance-media-core.md) | public discovery pass exists; playback/library source inventory still required | medium | medium |
| 4 | 58 | [Add one Media integration family](task-58-glance-media-expansion.md) | deferred until a real Ready media family is approved | medium | medium |
| 5 | 59 | [Build the Games page](task-59-glance-games-page.md) | public discovery pass done; Steam account/Twitch sources remain opt-in | medium | low-med |
| 6 | 60 | [Build the News page](task-60-glance-news-page.md) | curated public feed pass done; source and Pi acceptance remain | medium | low |
| 6 | 61 | [Build the Social page](task-61-glance-social-page.md) | curated public feed pass done; source and Pi acceptance remain | medium | low |
| 6 | 62 | [Unify visual and responsive design](task-62-glance-visual-polish.md) | CSS/page pass done; screenshots and performance measurements remain | medium | low |
| 6 | 63 | [Audit sources and privacy](task-63-glance-security-review.md) | blocked by 62 | medium | low-med |
| 6 | 64 | [Validate failures and performance](task-64-glance-performance.md) | blocked by 63 | medium | low-med |
| 6 | 65 | [Prove recovery and finish runbooks](task-65-glance-recovery-docs.md) | blocked by 64 | medium | low |
| optional | 66 | [Evaluate expansion and Dynacat](task-66-glance-future-evaluation.md) | blocked by 65 | medium | none |
| prep | 70 | [Review Beszel as the Glance external Hosting source](task-70-glance-beszel-hosting-source-review.md) | ✅ review done; adapter path selected after Pi auth/schema review | small-med | medium |
| prep | 71 | [Choose a safe Beszel-to-Glance auth bridge](task-71-glance-beszel-auth-bridge.md) | ✅ done (5d539d6) | small-med | medium |
| prep | 72 | [Implement the local Beszel summary adapter for Glance](task-72-glance-beszel-adapter.md) | ✅ done (7cda926; operator Pi data-path validation accepted) | medium | medium |
| prep | 73 | [Review and implement UniFi as the primary deep Network source](task-73-glance-unifi-network-source.md) | ✅ aggregate health widget done; live secret path set on Pi 2026-08-20 | small-med | medium |
| next | 74 | [Add Healthchecks and backup status to Glance Hosting](task-74-glance-healthchecks-backup-hosting.md) | API reviewed; backup heartbeat identified but host mount/exporter is not approved; needs read-only key | medium | medium |
| next | 75 | [Add private calendar and presence intelligence to Glance Home](task-75-glance-home-calendar-presence.md) | scaffold selected: ICS calendar + Home Assistant `person.*`; adapter/widget pending live inputs | medium | medium |
| next | 76 | [Add Plex/Tautulli media intelligence to Glance Media](task-76-glance-media-plex-tautulli.md) | proposed; needs Tautulli/Plex source and field-policy decisions | medium | medium |
| next | 77 | [Add Steam and Twitch sources to Glance Games](task-77-glance-games-steam-twitch.md) | public discovery and Steam Specials done; Steam/Twitch credentials and private account fields still pending | medium | medium |
| next | 78 | [Add Spotify and YouTube learning recommendations to Glance](task-78-glance-spotify-youtube-recommendations.md) | proposed; needs OAuth scope and local-recommendation decisions | med-large | medium |

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
