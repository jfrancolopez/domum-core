# Task 08 — Add catalog-consistency smoke tests  [shared-philosophy]

## Objective
Add a small `tests/` script (mirroring the sibling repo's
`tests/immich-secret-propagation-smoke.sh` pattern) that catches the class of
drift this audit found by hand: catalog entries pointing at missing files,
backup flags without defaults, and update-token keys missing from the
example config.

## Files involved
- `tests/catalog-consistency-smoke.sh` (new)
- `.github/workflows/validate.yml` (one new step)

## Reason
The service catalog in `bin/domum-core` is the single source of truth, but
nothing verifies the things it points at. This audit found two real bugs a
20-line test would have caught (`BACKUP_MUSICASSISTANT` missing default,
night-profile drift). A homelab does not need a test framework — one plain
bash script run by CI is the right weight.

## Implementation plan
Write `tests/catalog-consistency-smoke.sh` (plain bash, `set -euo pipefail`,
no framework) that:
1. Extracts `service_catalog()` rows by sourcing a stub or by running
   `bin/domum-core` with a trick — simplest: `awk` the heredoc block out of
   `bin/domum-core` (it sits between `service_catalog() {` and `EOF`).
2. Asserts for every row:
   - the `compose_rel` file exists (when not `-`);
   - when `backup_var` is not `-`, `grep -q "${backup_var}=\"\${${backup_var}:-"` matches
     `load_cfg()` in `bin/domum-core` (a default exists) **and** the flag
     appears in `config/domum-backup.conf.example`;
   - the `enable_var` appears in `config/domum.conf.example`.
3. Asserts every `*_AUTO_UPDATE` / `*_UPDATE_DELAY_DAYS` key defaulted in
   `load_cfg()` also appears in `config/domum.conf.example` (and vice versa).
4. Exits non-zero with a readable list of failures.
Then add a CI step `run: tests/catalog-consistency-smoke.sh`.

## Testing plan
- Run locally: passes on a clean tree.
- Mutate the catalog (add a fake row) and confirm it fails with a clear
  message; revert the mutation.
- shellcheck passes on the new script.

## Risk
Low — additive; CI-only. The awk extraction is coupled to the heredoc
format; keep the parser tolerant and fail loudly if it extracts 0 rows.

## Rollback
Delete the file and the CI step.

## Dependencies
Task 04 (otherwise the new test fails on day one — that's acceptable too,
just land 04 first or in the same PR).

## Estimated complexity / token size
Medium (~12k tokens).

## Suggested order
8.
