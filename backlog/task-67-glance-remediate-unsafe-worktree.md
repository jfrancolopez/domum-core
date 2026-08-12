# Task 67 - Remove unsafe uncommitted Glance implementation

## Objective

Remove only the uncommitted Glance implementation and documentation that
introduces fabricated data, unsupported widget syntax, unsupported JavaScript,
or false deployment claims. Preserve the approved Glance program, task-47
audit, and unrelated operator changes.

## Background

Task 47 found the production Glance service crash-looping because the current
configuration had no recognized `pages` section. The immediate outage was
repaired by restoring the last known-good two-page configuration from Git
history. Other uncommitted files still claim working Network, Games, Hosting,
and News implementations without verified sources, privacy approval, secrets,
or supported Glance `v0.8.5` syntax.

The operator explicitly approved reverting only this uncommitted implementation.
The previously committed Network work is not part of this task and requires a
separate review before it can be restored, changed, or deployed.

## Why This Exists

Leaving invalid configuration and false documentation in the worktree risks a
future agent deploying fabricated operational data, exposing private household
information, or reintroducing the Glance outage. Task 48 must begin from an
honest source of truth.

## Current Behavior

- Production now runs a restored two-page Glance configuration.
- The worktree still contains uncommitted draft Games, Hosting, and News pages,
  draft widget files, unsupported gaming-secret documentation, and misleading
  capability/service documentation.
- `dash` is public, so private integrations remain blocked by task 49.

## Desired Behavior

- Only the restored, currently running public-safe Glance configuration remains
  active.
- Documentation makes no claim that unimplemented widgets, credentials, or
  Network pages work.
- The approved program charter, tasks 47-66, audit, and unrelated files remain.
- Task 48 can design from verified facts without stale pseudo-implementation.

## Implementation Plan

1. Read `AGENTS.md`, the Glance program charter, task-47 audit, and the complete
   current diff. Confirm each target is uncommitted and matches this task.
2. Revert the uncommitted changes to:
   - `compose/monitoring/glance/pages/games.yml`
   - `compose/monitoring/glance/pages/hosting.yml`
   - `compose/monitoring/glance/pages/news.yml`
   - `docs/glance-capability-matrix.md`
   - `docs/services/glance.md`
3. Remove the untracked unsupported files under
   `compose/monitoring/glance/widgets/games/` and
   `compose/monitoring/glance/widgets/news/`, plus
   `docs/reference/gaming-secrets.md`.
4. Do not alter `compose/monitoring/glance/glance.yaml` or
   `compose/monitoring/glance.yml`; task 47 restored and validated their current
   production behavior.
5. Preserve `backlog/glance-dashboard-program.md`, tasks 47-66,
   `docs/glance-dashboard-audit.md`, `docs/README.md`, and unrelated files such
   as `opencode.jsonc`.
6. Validate the resulting running Glance configuration, inspect its logs, and
   confirm `dash` still returns HTTP 200. Do not add private data.
7. Update only the task status in `backlog/README.md` after operator acceptance.

## Affected Files

- The five tracked draft files listed in step 2
- The three untracked draft paths listed in step 3
- `backlog/README.md` (status only after completion)

Do not edit Homepage, Traefik policy, DNS, firewall, Tailscale, secrets, source
services, the restored Glance runtime files, or any committed Network work.

## Testing Plan

- Run `git diff --check` and confirm no removed file is an approved task, audit,
  or unrelated operator file.
- Run the required repository syntax/YAML checks applicable to changed files.
- Confirm Glance remains running and its logs contain no configuration error.
- Confirm `https://dash.${DOMUM_DOMAIN}` returns HTTP 200 locally.
- Run gitleaks if installed; otherwise record that it is unavailable.

## Rollback

Restore only the removed draft files from the remediation commit if a specific
file is needed for reference. Do not overwrite the running configuration,
secrets, or runtime data. Revert the remediation commit and recreate only
Glance if a rollback is necessary.

## Dependencies

Requires the task-47 production audit finding and operator approval. Blocks task
48 because the capability matrix and service documentation must not retain false
claims.

## Risks

The main risk is deleting valid operator or planning work. Inspect every target
before removal, preserve all approved backlog documents, and use no destructive
Git command. This task does not solve public exposure; task 49 owns that work.

## Complexity

Small repository cleanup; low runtime risk.

## Suggested Order

Run immediately after task 47 is accepted and before task 48.
