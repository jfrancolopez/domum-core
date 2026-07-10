# Task 36 — Unattended-safe update pipeline (supersedes task 31)

## Objective
Make container updates flow through exactly ONE gate, so the server can run
unattended for months while (a) never deploying an image the policy didn't
approve, and (b) never silently rotting — the system nags about aging pins
instead of either auto-breaking or auto-fossilizing.

> Supersedes `task-31-updates-apply-race-and-rollback.md` — same subsystem,
> now one coherent design. Task 31's digest-race fix and rollback command are
> absorbed below (sections D2 and D4).

## Background — the 2026-07-10 incident and the three holes it exposed
A routine `apply` recreated mariadb onto a previously pulled `mariadb:latest`
(12.3, a major ahead of the datadir) → crash loop → HA down until the image
was pinned back (full record in task 10). The delay-window model did not
fail conceptually; it was **bypassed**:

1. **`updates check` runs `docker pull`** — new images land locally during a
   "read-only" check.
2. **`apply` deploys whatever is local** — compose `up -d` recreates onto
   the newest local image with no delay/backup/history gates.
3. **The `*_AUTO_UPDATE` flags are inert** — no timer runs
   `updates apply-auto`; only `updates-check.timer` exists. So the governed
   path never executes while the ungoverned path (pull + apply) does.

Operator's stated policy (2026-07-10): prefers reliability over freshness,
server will be unattended, but fears pinning everything ⇒ ancient software.
Resolution: **old-but-patched OS + tiered container policy + rot-nagging.**
Debian security patches (already automated via
`domum-core-security-patches.timer`) cover the real attack surface for
years; containers need to be *deliberate*, not *fresh*.

## Design

### D1 — Pull-free `updates check`
Replace the `docker pull` in `updates_check()` with a registry-side digest
query: `docker manifest inspect "$image_ref"` (no download; works for Docker
Hub and ghcr.io; add `--insecure` never). Record the returned digest as the
candidate.

Implementation care: `manifest inspect` returns the **repo/index digest**,
while the current code compares local image IDs (`.Id`, the config digest).
Compare like with like: running side uses
`docker inspect --format '{{index .RepoDigests 0}}'` (strip the `name@`
prefix), candidate side uses the manifest digest. A multi-arch tag's
RepoDigest is the index digest when pulled by tag, so they match. Services
running images that predate this scheme may have empty RepoDigests — treat
as "unknown, cannot compare" (print `?`), never as "update available".

Fallbacks: if `docker manifest inspect` is unavailable or the registry
refuses, print `?` for that service and move on — never fall back to
pulling. After this change, `apply` cannot roll out surprises because
nothing new exists locally until D2 pulls it. (Task 09's apply-warning stays
as cheap defense-in-depth against *manual* `docker pull`s.)

### D2 — Digest-verified `updates apply` (absorbed from task 31)
In `updates_apply_one()`, after `compose_cmd pull`:
```bash
pulled="$(docker inspect --format '{{index .RepoDigests 0}}' "$image_ref" | ...)"
if [[ "$pulled" != "$CANDIDATE_DIGEST" ]]; then
  warn "$svc: registry moved past the aged candidate; re-recording and resetting the delay window."
  record_update_candidate ...; return 0   # --force proceeds, loudly
fi
compose_cmd up -d "$cs"
```
Deploy-what-aged, or decline and re-age. No retagging magic.

### D3 — Scheduled `apply-auto` (makes the auto tier real)
New units `systemd/domum-core-updates-apply.{service,timer}`:
`updates apply-auto`, daily `OnCalendar=*-*-* 06:00`, `Persistent=true`,
installed disabled by the existing `schedule install-maintenance` glob.
Ordering rationale: backups 02:30 → check 05:15 → apply-auto 06:00, so the
backup gate always sees a fresh backup and candidates are current. Only
apps with `<APP>_AUTO_UPDATE=1`, elapsed delay, and passing backup gate
apply; everything else just logs "skipped".

### D4 — `updates rollback <app>` (absorbed from task 31)
1. Read newest `update-history/<app>-*.env` with `RESULT=success` and
   non-empty `FROM_IMAGE`; verify the image ID still exists locally.
2. `docker tag "$FROM_IMAGE" "$image_ref"` + `compose_cmd up -d "$cs"`;
   record `RESULT=rollback`.
3. Guard in `cleanup_images`: never prune an ID that is the FROM_IMAGE of
   the newest history entry per service (keeps rollback possible).
4. Config-pinned services (task 10 `${SERVICE}_IMAGE` vars): print "move the
   pin in config and apply" instead of retagging.
5. Warn on schema-downgrade risk when rolling back mariadb/home-assistant.

### D5 — Anti-rot nag (the answer to "unattended ⇒ ancient software")
Zero-infrastructure staleness signal: every image records its build time in
`docker inspect --format '{{.Created}}'`. Add to `run_checkup()` (warning)
and the weekly report (task 25, one table column): per enabled service,
image age in days vs a per-tier threshold:
- auto tiers: age > 60d ⇒ "auto-update path may be stuck — check
  updates status" (auto services should never get old; age here means the
  pipeline is broken, which is exactly worth a nag);
- manual/pinned tier: age > 270d ⇒ "pin review due: <svc> image built
  <date>". Thresholds as config defaults (`UPDATE_ROT_*_DAYS`), not magic
  numbers.
No registry scraping, no version APIs, nothing to maintain.

### D6 — Policy: the tier table (document in docs/operations/updates.md)
| Tier | Services | Setting |
|---|---|---|
| OS security | Debian via unattended-upgrades | existing timer, keep enabled |
| Auto within major | traefik (pin `:v3`, task 10), adguard-home | auto=1, delay 1–3d |
| Auto with delay | esphome, nodered, musicassistant, actual-budget, obsidian-sync, vaultwarden | auto=1, delay 7–14d, backup-gated |
| Manual, pinned | mariadb, home-assistant, zigbee2mqtt, zwave-js-ui | auto=0, pinned tags (task 10), bumped when the rot-nag fires |

Rationale recorded so it is not re-litigated: mariadb/HA have data
migrations; z2m/zwave majors can force device re-pairing; vaultwarden is
deliberately in the auto tier because it is security-exposed (timely beats
manual) and backup-gated. Update `config/domum.conf.example` defaults to
match (currently everything except traefik/adguard is auto=0 — flip the
"auto with delay" tier to 1 so the example encodes the policy).

## Affected files
- `bin/domum-core` — `updates_check`, `record_update_candidate` comparison
  fields, `updates_apply_one`, new `updates_rollback`, `cleanup_images`
  guard, checkup rot-nag, usage text
- `systemd/domum-core-updates-apply.service`, `.timer` (new)
- `config/domum.conf.example` (tier defaults + `UPDATE_ROT_*_DAYS`)
- `docs/operations/updates.md` (rewrite around the pipeline + tier table),
  `docs/operations/cli-cheatsheet.md`, `docs/operations/maintenance-timers.md`
- `backlog/task-31-updates-apply-race-and-rollback.md` (already marked
  superseded)

## Testing plan
- Sandbox with a local registry or public tags: `updates check` records
  candidates **without** the image appearing in `docker images` (the
  acceptance test for D1).
- Fabricate candidate files: apply-auto respects auto flags, delay, backup
  gate; digest mismatch declines; `--force` proceeds loudly.
- Rollback round-trip on a small service; `cleanup images --dry-run` spares
  the FROM_IMAGE.
- Rot-nag: temporarily set threshold to 0 ⇒ warnings appear for all.
- `systemd-analyze verify` on new units; timer fires order confirmed via
  `systemctl list-timers`.
- On the Pi: one full supervised cycle (check → status → apply-auto
  --dry-run → apply-auto) before walking away.

## Rollback strategy
Each design item is a separate commit. D1 revert restores pull-based check;
D3 is disable-the-timer; D2/D4/D5 are function-local. No data migrations.

## Dependencies
- Task 10 (pins) can land before or after; D6 references its vars.
- Task 09 remains open as defense-in-depth (reduced severity after D1).
- Weekly report (task 25) consumes D5's rot data — soft ordering.

## Risks
Medium: this is the update path of a production host. Mitigations: dry-run
paths everywhere, timers ship disabled, the backup gate is preserved
end-to-end, and the supervised first cycle on the Pi.

## Estimated complexity
Medium-large (~18k tokens).

## Suggested order
Phase 3, first item (before 09; task 10's pins can ride along or precede).
