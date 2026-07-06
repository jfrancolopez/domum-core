# Task 13 — Zigbee network key rotation runbook (then drop the gitleaks allowlist)

## Objective
Turn the "rotation tracked separately" note in `.gitleaks.toml` into an
actual, documented, scheduled operation — and remove the allowlist once done.

## Files involved
- `docs/reference/secrets.md` or a new `docs/reference/zigbee-key-rotation.md`
- `.gitleaks.toml` (allowlist removal — only after rotation)
- `compose/automation/zigbee2mqtt/configuration.yaml` (verify `!secret`
  indirection still holds; `secret.yaml` stays untracked)

## Reason
The historical Zigbee network key was committed in plaintext and still lives
in git history; the repo is on GitHub. The current config uses
`!secret network_key` and gitleaks allowlists the path so CI passes, but the
key itself has not been rotated — anyone with historical repo access can
decrypt Zigbee traffic / join the network. Rotation is disruptive (every
device re-pairs on key change... actually Zigbee2MQTT supports changing
`network_key` but all devices must be re-paired), which is why it stalled.
It needs a written procedure and a chosen maintenance window, not code.

## Implementation plan (documentation task — no live changes)
1. Write the runbook: current Z2M key-rotation guidance (new `network_key`
   in `secret.yaml`, `pan_id` change recommended, full device re-pair,
   estimated time per device count), backup first
   (`sudo domum-core backups run`), rollback = restore old `secret.yaml` +
   zigbee2mqtt data dir from the service backup.
2. List the follow-ups inside the runbook: after rotation, delete the
   allowlist block from `.gitleaks.toml` and confirm CI still passes
   (history scans will flag the old key — decide then between keeping a
   narrower commit-scoped allowlist or accepting the finding as resolved).
3. Do NOT rewrite git history — not worth it for a rotated key; note that
   decision explicitly in the runbook.

## Testing plan
- Runbook peer-readable: every command copy-pasteable, paths real.
- gitleaks change is deferred; no CI impact from this task.

## Risk
None for the doc. The rotation itself is medium-risk/high-effort
(device re-pairing) — that is exactly why it gets a runbook and a scheduled
window instead of an agent doing it.

## Rollback
n/a (documentation).

## Dependencies
None.

## Estimated complexity / token size
Small (~6k tokens).

## Suggested order
13 (doc anytime; rotation when the operator schedules it).
