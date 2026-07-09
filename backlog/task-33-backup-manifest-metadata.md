# Task 33 — Structured backup manifest (metadata that makes recovery deterministic)

## Objective
Every backup run writes one machine- and human-readable manifest that answers,
years later: what was backed up, from what software state, and how do I know
it is intact? The restore wizard and restore verification consume it.

## Evaluation first — what already exists (don't duplicate)
- The **recovery pack** (weekly) already captures: git revision, rendered
  compose, service inventory + image digests, backup-target URLs, and a
  `MANIFEST.txt` with per-file SHA-256 — but only for the pack's own
  contents, and only weekly.
- **restic** snapshots carry host, time, paths, and content-addressed
  integrity (a snapshot is its own checksum tree; `restic check` verifies it).
- `validate_backup_artifact()` checks staging tars are non-empty and
  gzip-valid at creation time.

The genuine gaps: nothing records *per-run* context (versions, service set,
artifact checksums) that rides **inside** the backup itself; nothing records
which systemd timers were enabled (host state that recovery must recreate);
and restore-time verification has no independent checksum list to check
against. A single manifest file closes all three.

## Design (deliberately one file, one function)
New helper in `bin/domum-core`, called at the end of the staging phase of
`backups run` (before restic push):

`$STATE_ROOT/service-backups/BACKUP-MANIFEST.json` — overwritten each run,
so exactly one current manifest rides in every restic snapshot (and history
lives in restic snapshots, not in manifest rotations):

```json
{
  "manifest_schema": 1,
  "created_at": "2026-07-12T02:31:07-04:00",
  "host": "domum-pi",
  "git_commit": "8bfee98...",
  "git_dirty": false,
  "os_release": "Debian GNU/Linux 13 (trixie)",
  "kernel": "6.12.x-rpi",
  "docker_version": "28.x",
  "restic_version": "0.17.x",
  "enabled_services": [ {"name":"home-assistant","image":"ghcr.io/...@sha256:..."} ],
  "backup_flags": {"BACKUP_HOMEASSISTANT":1, "...": "..."},
  "enabled_timers": ["domum-core-backups.timer", "domum-core-checkup.timer"],
  "targets": ["local","hetzner"],
  "artifacts": [
    {"path":"homeassistant/ha-20260712-023045.tar.gz","size":123456,"sha256":"..."},
    {"path":"mariadb/mariadb-all-20260712-023101.sql.gz","size":9876,"sha256":"..."}
  ]
}
```

Implementation notes:
- Reuse, don't re-derive: the service-inventory logic exists in
  `recovery_pack_create` — extract a shared helper both callers use.
  `sha256_of_file`, `file_size`, `json_array_from_items` exist.
- `enabled_timers`: `systemctl list-unit-files 'domum-core-*.timer'
  --state=enabled --no-legend` — this is the host state the disposable-OS
  philosophy needs recorded (the restore wizard, task 22, replays it).
- jq optional: emit with printf like the existing JSON fallback; jq only for
  pretty-printing if present. No new dependencies.
- Also drop the same file into the recovery-pack staging (`meta/`), replacing
  the ad-hoc `service-inventory.txt` + `backup-targets.txt` over time (keep
  those files for one transition period, then remove — note in the task
  when implementing).
- `manifest_schema` is a plain integer with an "additive changes only" rule.
  No schema registry, no migration code — if a field must change meaning,
  bump the integer and teach the two consumers.

Explicitly rejected (simplicity): per-artifact sidecar `.sha256` files
(clutter, same information), manifest rotation/history (restic snapshots are
the history), signing (the restic repo is already authenticated by its key;
the AGE pack by its recipient).

## Consumers (this is what makes it worth having)
1. **Restore verification** (task 23): after restoring the critical set,
   verify each restored artifact's sha256 against the manifest — a true
   end-to-end integrity check independent of restic's internals.
2. **Restore wizard** (task 22): before restoring, print the manifest
   summary — "snapshot from 2026-07-12, commit 8bfee98, 14 services, Debian
   13" — so the operator confirms they are restoring what they think.
   After restore: offer to re-enable the recorded timers.
3. **Weekly report** (task 25): one line — manifest present + age.
4. **Future-you, manually**: `restic dump latest .../BACKUP-MANIFEST.json`
   answers "what is in this repo?" without any domum tooling installed.

## Affected files
- `bin/domum-core` (manifest helper + call in `backups_cmd run` staging;
  shared inventory helper refactor touching `recovery_pack_create`)
- `docs/backups/overview.md` (short "What the manifest records" section)

## Testing plan
- `sudo domum-core backups run --dry-run` → prints "would write manifest".
- Real run → file exists, `jq . ` parses it (or python3 -m json.tool),
  checksums match `sha256sum` of the listed artifacts, timers list matches
  `systemctl list-timers`.
- `restic dump latest` of the manifest works from both targets.
- Recovery pack still builds; its meta/ contains the manifest.

## Rollback strategy
Additive — revert the commit; old backups without manifests remain fine
(both consumers must treat a missing manifest as "informational skip", never
an error, or old snapshots become un-restorable by wizard policy).

## Dependencies
- After task 21 (manifest describes the *final* staging layout).
- Before/with tasks 22 and 23 (its consumers). If 22/23 land first they add
  the manifest hooks when this lands.

## Risks
Low. Keep the JSON emission dumb; malformed JSON is caught by the testing
plan's parse step.

## Estimated complexity
Small–medium (~10k tokens).

## Suggested order
Phase 1, immediately after task 21.
