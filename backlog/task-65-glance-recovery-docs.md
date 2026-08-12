# Task 65 — Prove Glance recovery and finish operator runbooks

## Objective

Prove the complete dashboard rebuilds from Git plus the existing external-secret
recovery process, and publish final evidence/runbooks/deliverables. Do not change
widgets, visual design, or config; recovery-blocking defects become new tasks.

## Background

Git is authoritative, the OS is disposable, and private credentials live under
`/etc/domum-core/secrets` and the encrypted recovery mechanism. Tasks 50-64
create and harden the dashboard; this task proves another fresh system can
reconstruct it without manual container edits or undocumented files.

## Current Behavior

At task start, all seven pages should be approved and hardening evidence should
exist. Recovery may still depend on undocumented file modes, secret names,
assets, includes, provider-side setup, or deployment ordering.

## Desired Behavior

A stressed operator can rebuild Glance from fresh Debian using the repository
and documented secret restoration, validate it with dummy credentials, deploy it
through the normal full-stack flow, and verify every page. Final documentation
contains no secret values or private screenshots.

## Implementation Plan

1. Inventory every tracked config/include/template/asset and every external
   credential name, file mode, scope, and owner. Identify undocumented state.
2. In a disposable environment, clone Git, create dummy secret files with safe
   values/modes, render Compose, run full Glance validation, and start only the
   isolated validation fixture if task 50 documented one. Do not start the home
   automation stack outside the Pi.
3. Verify no required source file exists only in a container volume, ignored
   runtime path, operator shell history, or manual container edit.
4. Document real Pi recovery order through existing bootstrap/update/apply/checkup
   and encrypted secret recovery. `domum-core apply` is full-stack; state the
   maintenance/candidate checks clearly.
5. Finish the operator runbook: architecture, page map, widget/data-source maps,
   credential inventory without values, cache budget, privacy, deploy/reload,
   troubleshooting, adding a page/widget, community updates, limitations, and
   rollback.
6. Publish final validation evidence: files changed, services restarted,
   sanitized page screenshots, desktop/mobile checks, performance before/after,
   recovery test, known limitations, remaining integrations, truthful untested
   items, and Git diff/commit summary.
7. Run all repository/secret checks and obtain final operator approval.

## Affected Files

- `docs/services/glance.md`
- `docs/dashboard-architecture.md`
- `docs/glance-dashboard-architecture.md`
- `docs/glance-capability-matrix.md`
- `docs/glance-dashboard-validation.md` (new)
- `docs/reference/secrets.md`
- `docs/README.md`
- `backlog/README.md` (status only)

Config defects require a new numbered task and must not be fixed here.

## Testing Plan

- Run all `AGENTS.md`, Compose, Glance, YAML, link, and gitleaks checks.
- Complete the disposable reconstruction with dummy credentials.
- On the Pi, verify the documented full-stack deployment/checkup and every page.
- Review screenshots/log excerpts for private data before tracking.
- Have another agent follow the runbook without chat context and report gaps.

## Rollback

Revert documentation/evidence changes. No runtime rollback exists because config
is out of scope. Never delete data or secrets.

## Dependencies

Requires completed and operator-approved task 64.

## Risks

Recovery tests can accidentally touch production or expose credentials in logs.
Use disposable fixtures and dummy values off-Pi, sanitize evidence, and never
claim a production restore that was not performed.

## Complexity

Medium recovery validation and documentation; low operational risk.

## Suggested Order

Final mandatory phase before optional task 66.
