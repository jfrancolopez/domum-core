# Task 40 — Split runtime-written app config from tracked templates

## Objective

Stop runtime services from dirtying tracked files or writing secret-derived
state into git-tracked paths.

## Background

During the 2026-07-15 reboot/auth hardening work, two tracked files became dirty
from normal service runtime behavior:

- `compose/automation/zigbee2mqtt/configuration.yaml` was rewritten by
  Zigbee2MQTT to add a `devices:` block with joined device IDs.
- `compose/productivity/obsidian-sync/etc/local.ini` was rewritten by CouchDB to
  add an `[admins]` block containing password hashes.

The dirty files blocked `sudo domum-core update`, because update correctly warns
before resetting local changes. The Obsidian case is also a secret hygiene risk:
admin password hashes must never be committed.

## Current Behavior

- Zigbee2MQTT uses the repo-tracked `configuration.yaml` as its live config.
- Obsidian Sync mounts the tracked `etc/` directory as CouchDB local config.
- Runtime writes can reappear after service restart or reboot.
- Operators must manually restore the tracked files before updates can proceed.

## Desired Behavior

- Tracked files are templates or static config only.
- Runtime-written files live in ignored paths.
- Reboots and normal service starts do not dirty `git status`.
- CouchDB admin hashes stay outside git-tracked files.

## Implementation Plan

1. Verify current app behavior on the Pi after a clean reboot:
   - `git status --short`
   - `docker logs zigbee2mqtt --since 10m`
   - `docker logs obsidian-sync --since 10m`
2. For Zigbee2MQTT, decide the smallest safe split:
   - Option A: keep tracked `configuration.yaml` minimal and configure
     Zigbee2MQTT not to persist device names there, if supported.
   - Option B: move live `configuration.yaml` to an ignored runtime path and add
     a tracked `.example` or template copied by setup.
   - Reject committing live `devices:` entries: they are local runtime state.
3. For Obsidian Sync, prevent CouchDB from writing admin hashes into tracked
   `local.ini`:
   - Prefer mounting static tracked tuning config read-only and using a separate
     ignored CouchDB runtime config path for generated admin state.
   - If CouchDB requires writing into `local.d`, move the whole live `etc/`
     mount out of tracked files and keep a tracked template elsewhere.
4. Update `.gitignore` for any new runtime paths.
5. Update docs for the new template/runtime split.
6. Run `sudo domum-core apply`, restart only affected services, then verify
   `git status --short` remains clean after restart.

## Affected Files

- `compose/automation/zigbee2mqtt.yml`
- `compose/automation/zigbee2mqtt/configuration.yaml` or a new template file
- `compose/productivity/obsidian-sync.yml`
- `compose/productivity/obsidian-sync/etc/local.ini` or a new template file
- `.gitignore`
- `docs/services/obsidian-sync.md`
- `docs/services/mqtt.md` or a Zigbee2MQTT service doc if added later

## Testing Plan

- `bash -n bin/domum-core bin/domum-core-backup install.sh`
- `shellcheck bin/domum bin/domum-core bin/domum-core-backup bin/night-profile.sh install.sh`
- `yamllint -c .yamllint.yml .`
- `sudo domum-core configure --validate`
- `sudo domum-core apply`
- Restart `zigbee2mqtt` and `obsidian-sync` once.
- Confirm:
  - both containers start cleanly;
  - Zigbee2MQTT reports joined devices and publishes to MQTT;
  - Obsidian Sync authenticates with `OBSIDIAN_COUCHDB_USER` and
    `OBSIDIAN_COUCHDB_PASSWORD`;
  - `git status --short` remains clean.

## Rollback

Revert the compose/template changes and restore the previous tracked config
files from git. Do not delete runtime data directories.

## Dependencies

Related to task 17, but smaller and urgent because these runtime writes already
blocked updates and exposed CouchDB password hashes in a tracked file.

## Risks

Medium operational risk: both services are live. Keep changes minimal and test
one service at a time. Do not combine with Zigbee network-key rotation or any
Obsidian data migration.

## Complexity

Small-medium code/config, medium validation.

## Suggested Order

Hygiene phase, before broader task 17. Do Obsidian first because it involves
secret-derived hashes, then Zigbee2MQTT.
