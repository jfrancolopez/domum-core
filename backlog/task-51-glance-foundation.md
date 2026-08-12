# Task 51 — Build the modular Glance foundation

## Objective

Create a Git-tracked modular Glance layout with navigation, shared styling, and
a safe migration of the existing two pages. Do not add API integrations.

## Background

The current service starts with one 145-line `glance.yaml`; the config directory
is mounted read-only. The target is seven pages under the existing
`compose/monitoring/glance/` convention. Task 48 defines the page map and task 50
pins the release, validates config, and establishes secret-name plumbing.

Upstream examples support page includes and custom assets in recent versions,
but this task must verify syntax against the exact selected version. Do not copy
an example merely because it works on upstream `main`.

## Current Behavior

- Two pages are inline in one file.
- There is no modular page/include tree, custom CSS asset, provenance log, or
  page-level acceptance workflow.

## Desired Behavior

Git can recreate an identical dashboard skeleton. Existing content still
renders. Empty future pages are not shown as fake dashboards. Task-50 validation
covers the complete include tree.

## Implementation Plan

1. Confirm task-50 validation and the pinned release's include/asset syntax.
2. Add the minimal modular tree supported by that version, likely
   `glance.yaml`, `pages/`, `widgets/`, and `assets/` under the current directory.
   Do not force unused `templates/` subtrees or placeholder pages.
3. Move existing Domum/Technology content without semantic redesign, using
   includes only after validation proves them. Preserve a reviewable diff.
4. Implement navigation names/order approved in task 48. Add only pages with
   real content; future page files may be staged but must not render empty cards.
5. Build two small visual prototypes using real existing widgets: dense NOC and
   media-rich subtle cyberpunk, both retaining Dracula/Domum continuity. Capture
   sanitized comparison screenshots and obtain one operator choice before final
   CSS. Avoid fonts/libraries or large remote assets.
6. Add only lightweight, locally tracked CSS/assets needed for the chosen base.
   Dynamic colors must use Glance theme variables and real states.
7. Update Glance docs with file layout, adding a page/widget, visual decision,
   deploy/reload behavior, and exact rollback.

## Affected Files

- `compose/monitoring/glance/glance.yaml`
- new tracked files under `compose/monitoring/glance/pages/`, `widgets/`, and
  `assets/` only as justified
- `docs/services/glance.md`
- `backlog/README.md` (status only)

Do not touch Homepage files, source services, global proxy/authentication, DNS,
firewall, or runtime data.

## Testing Plan

- Run all repository verification commands from `AGENTS.md`.
- Render all Compose files using CI's environment and all-service profile.
- Run the new Glance validation against the complete include tree.
- On the Pi, deploy through the normal Git flow; confirm old content, includes,
  navigation, reload, logs, and resource delta.
- Test target widths and both direct and Homepage-embedded views without editing
  Homepage.
- Run gitleaks and inspect staged names before commit.

## Rollback

Revert the foundation commit, run `sudo domum-core update`, then use a supervised
full-stack `sudo domum-core apply` and `sudo domum-core checkup`. Inspect pending
update candidates first because apply is not service-targeted. Do not delete
directories or secret files and never run `docker compose down`.

## Dependencies

Requires completed task 50. Private widgets remain out of scope.

## Risks

Include-path mistakes and broad CSS can take Glance offline or break every page.
Keep migration mechanical, validate before deploy, and preserve prior config in
Git history. Auth/proxy changes are out of scope.

## Complexity

Medium configuration/design and Pi validation; low operational risk.

## Suggested Order

Phase 1. Commit foundation separately from any page expansion.
