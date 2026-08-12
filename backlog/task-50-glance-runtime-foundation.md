# Task 50 — Pin, validate, and plumb Glance secrets

## Objective

Make the Glance runtime reproducible before modular page work: select an audited
release, align the repository update policy, add full-config validation, and
establish optional external-secret plumbing without adding private widgets.

## Background

The current Compose file uses `glanceapp/glance:latest`; CI checks YAML/Compose
but does not parse Glance templates/includes with the running release; and Glance
has no credential environment/file convention. Task 47 records the actual image,
task 48 chooses architecture, and task 49 proves private access.

## Current Behavior

- Mutable `latest` can change syntax/behavior without a config review.
- `GLANCE_AUTO_UPDATE=1` in the example conflicts with exact reproducibility if
  an immutable release is selected.
- CI cannot catch Glance-specific include/template errors.
- No Glance secret values are tracked, which must remain true.

## Desired Behavior

Production and CI use one reviewed Glance release policy. Version bumps are
manual, documented, and validated. The complete future include tree can be
parsed in CI. Optional credential names can reach Glance from
`/etc/domum-core/secrets` without values in Git or mandatory empty files that
prevent startup.

## Implementation Plan

1. Verify the running version/digest and current stable release, release notes,
   architecture support, include/custom-asset behavior, and config reload model.
2. Select an explicit released tag or digest and set Glance to manual review in
   the example update policy. Record the bump procedure. If existing update
   machinery cannot represent this safely without `bin/domum-core` changes,
   stop and create a separate exact backlog task.
3. Determine the release's real validation behavior from its binary `--help` and
   official docs. Add a bounded repository/CI validation using that exact image.
   If no static validator exists, document the limits of a no-network startup
   check; never call it full semantic/live-data validation.
4. Add the minimum optional secret/env mechanism consistent with
   `/etc/domum-core/secrets`. Track variable/file names only and ensure Glance
   still starts before any optional credential exists.
5. Update CI Compose dummy environment only as needed; no real endpoint, ID,
   token, private feed, or address belongs there.
6. Document version updates, validation, secret creation/modes, recovery impact,
   and rollback. Do not modularize pages or add CSS/widgets in this task.

## Affected Files

- `compose/monitoring/glance.yml`
- `config/domum.conf.example`
- `.github/workflows/validate.yml`
- one minimal validation script under `tests/` if required
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md` (status only)

`bin/domum-core` is out of scope; a required CLI/update-model change becomes a
new task. Do not touch Glance page YAML, Homepage, source services, or runtime data.

## Testing Plan

- Run every `AGENTS.md` check, all-service Compose rendering, the new Glance
  validation, and gitleaks.
- Prove malformed Glance config fails the validator and the current config passes.
- Prove optional missing credentials do not block current public-safe pages.
- On the Pi, use normal supervised full-stack deploy/checkup; confirm reported
  version, logs, access boundary, and existing pages.
- Verify no secret value/path content enters the diff or CI logs.

## Rollback

Revert the runtime-foundation commit, update the checkout, then run a supervised
full-stack apply and checkup after inspecting update candidates. Do not delete or
overwrite secret files.

## Dependencies

Requires completed and Pi-accepted task 49.

## Risks

An unsupported image policy can silently disable updates; an incorrect validator
can provide false confidence; required missing env files can take Glance down.
Use the exact release, test negative cases, and stop on update-model conflict.

## Complexity

Medium runtime/CI work; low-medium operational risk.

## Suggested Order

Phase 1 before modular config or page changes.
