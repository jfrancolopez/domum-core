# Task 38 — Ignore ESPHome live config and secrets

## Objective
Prevent ESPHome's live bind-mount contents from appearing as untracked git
files, especially `secrets.yaml`, without deleting or moving any existing
ESPHome data.

## Background
During task 37 work on the production checkout, `git status --short` showed an
untracked directory:

```text
?? compose/automation/esphome/
```

That directory is the ESPHome container bind mount from
`compose/automation/esphome.yml` (`/opt/domum-core/compose/automation/esphome:/config`).
It currently contains runtime state and secret-bearing files such as
`secrets.yaml`, `.esphome/`, `.device-builder.json`, and a nested `.git/`.

This is a git hygiene and secret-safety gap. The root `.gitignore` already
ignores generic `data/` directories and one Zigbee2MQTT secret file, but it does
not ignore ESPHome's live config directory.

## Why It Exists
Secrets must never touch git. A constantly untracked live config directory also
makes `git status` noisy during production incidents, increasing the chance that
an operator stages the wrong path or misses real repository drift.

## Current Behavior
- ESPHome live config is mounted directly under `compose/automation/esphome/`.
- The path is not ignored by root `.gitignore`.
- `git status` reports the whole directory as untracked.

## Desired Behavior
- ESPHome live config remains exactly where it is for the running container.
- Git ignores `compose/automation/esphome/` and never offers to stage its
  contents.
- No existing live ESPHome files are read, copied, deleted, or normalized.

## Implementation Plan
1. Add `compose/automation/esphome/` to the root `.gitignore` with a short
   comment that it is live ESPHome bind-mount data.
2. Run `git status --short` and verify the ESPHome directory disappears from
   untracked output.
3. Do not create placeholder files inside the ignored directory; the directory
   belongs to the service, not git.

## Affected Files
- `.gitignore`

## Testing Plan
- `git status --short` no longer reports `compose/automation/esphome/`.
- `git check-ignore -v compose/automation/esphome/secrets.yaml` shows the new
  ignore rule.

## Rollback Strategy
Remove the ignore rule. This only changes git visibility; it never affects live
ESPHome data.

## Dependencies
None.

## Risks
Low. The main risk is hiding a file that someone expected to commit, but the
path is runtime config with secrets and should be protected by backups, not git.

## Decisions and Rejected Alternatives
- Decision: ignore the whole directory. Reason: it is the live `/config` bind
  mount and contains multiple runtime/secret files.
- Rejected: ignore only `secrets.yaml`. Reason: `.esphome/` and device-builder
  files are runtime state and would keep `git status` noisy.
- Rejected: move ESPHome config out of the repo tree now. Reason: runtime data
  relocation is already the larger future task 17; this task is the smallest
  immediate secret-safety fix.

## Estimated Complexity
Trivial.

## Suggested Order
Phase 4 hygiene, or sooner if `git status` noise causes operator confusion
during another incident.
