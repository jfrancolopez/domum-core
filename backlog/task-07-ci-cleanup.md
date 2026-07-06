# Task 07 — CI cleanup and alignment with the sibling repo  [shared-philosophy]

## Objective
Remove copy-paste leftovers from the validate workflow and adopt the two
cheap checks the sibling repo (`domum-core-media`) already runs: a
`bash -n` syntax gate and an explicit shellcheck severity.

## Files involved
- `.github/workflows/validate.yml`

## Reason
- The compose-validate job runs
  `--profile core --profile night --profile media --profile ai` — the
  `media` and `ai` profiles do not exist anywhere in this repo's compose
  files (only `core` and `night` are used). Harmless today, but it documents
  services that were intentionally removed and confuses future readers.
- The sibling repo runs `bash -n bin/... install.sh` before shellcheck —
  a fast, zero-dependency guard that catches syntax errors the moment they
  land. This repo lacks it.
- Keeping both repos' CI shaped the same is part of the shared engineering
  foundation (both already share yamllint-style limits and compose config
  validation; the sibling lacks gitleaks/yamllint — that's for the media
  repo's own backlog, not this task).

## Implementation plan
1. Drop `--profile media --profile ai` from the compose config command.
2. Add a `bash -n bin/domum bin/domum-core bin/domum-core-backup bin/night-profile.sh install.sh`
   step ahead of shellcheck (adjust the list if task 06 has removed
   `night-profile.sh`).
3. Leave yamllint, gitleaks, and shellcheck jobs as-is — they work.

## Testing plan
- Push to a branch; all four jobs green.
- Intentionally break a script locally and confirm `bash -n` fails (do not
  push the breakage).

## Risk
Low — CI only.

## Rollback
Revert.

## Dependencies
Soft ordering with task 06 (file list in the `bash -n` step).

## Estimated complexity / token size
Small (~4k tokens).

## Suggested order
7.
