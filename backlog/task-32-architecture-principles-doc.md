# Task 32 — Architecture principles + feature acceptance checklist

## Objective
Write `docs/reference/architecture-principles.md`: the permanent design
philosophy of domum-core plus the checklist every future change must satisfy.
Guardrails, not a law book — one document, under two pages, that keeps months
of future AI sessions and future-operator decisions consistent.

## Why one document, not two
The operator asked for (a) an architecture-principles doc and (b) a feature
acceptance checklist. They are the same artifact at two zoom levels: the
checklist is the per-PR enforcement of the principles. Two documents would
drift apart; one document with a checklist section cannot. (Decision made in
the 2026-07-09 audit round 2 — revisit only if the checklist grows past ~15
items, which would itself be a smell.)

## Background
The repo has matured past the point where its philosophy is inferable from
code: the backlog README carries "ground rules", the CLI header comment
carries operating rules ("audit before change; backup before update; never
delete existing files; never rotate secrets"), `docs/reference/audit.md`
carries history, and the rest lives in chat transcripts. Each future session
re-derives the philosophy — or worse, doesn't.

## Content plan (the actual principles — draft to refine, not reinvent)

### Part 1 — Principles
1. **Git is the source of truth.** Everything needed to rebuild lives in the
   repo; everything secret or runtime lives outside it. If a rebuild would
   need a file that is in neither git nor the backups, that file is a bug.
2. **The OS is disposable.** Recovery means a fresh Debian image + one
   bootstrap command + restored backups — never preserving or transplanting
   an old root filesystem. Any feature that depends on accumulated host
   state must either converge that state automatically (`init`) or capture
   it in the recovery pack/backups. Cloning a drive is a convenience for
   *planned* hardware swaps, never the recovery plan.
3. **A backup that has never been restored is a hope, not a backup.**
   Restore paths get tested on a schedule (automated monthly + annual fire
   drill); restore tooling gets the same care as backup tooling.
4. **The simplest solution that is reliable enough.** Prefer standard Debian
   packages, plain bash, systemd timers, and boring designs. Clever is a
   maintenance cost.
5. **Every feature must justify its long-term maintenance cost.** Features
   default to "no". Deleting an unused feature beats rebuilding it nicely.
6. **Secrets never touch git.** `/etc/domum-core/secrets` (0700, root) is the
   only home for secrets; the AGE-encrypted recovery pack is the only way a
   secret leaves the host. Never auto-rotate, never auto-generate keys.
7. **Documentation is part of the implementation.** A feature without docs
   is unfinished; a runbook that a stressed operator cannot execute verbatim
   at 2 a.m. is a defect, not a style issue.
8. **Safe by default.** Destructive actions require explicit flags and fresh
   backups; dry-run paths exist before destructive paths; timers install
   disabled; new services ship disabled; nothing deletes user data
   automatically — ever.
9. **One source of truth per fact.** The service catalog defines services;
   compose files define runtime; config defines policy. Duplicated facts
   (a second list of services, a second SMTP config) are drift factories.
10. **The Pi is production.** Changes reach it through git → `update` →
    `apply` → `checkup`, not ad-hoc edits on the host.

### Part 2 — Feature acceptance checklist
Before merging any change:
- [ ] Reuses existing plumbing (catalog, `restic_for_target`, checkup
      accumulators, email sender) instead of adding parallel machinery.
- [ ] No new dependencies beyond standard Debian packages — or the task
      explains why and what it costs.
- [ ] No duplicated logic/facts (grep first; extend, don't fork).
- [ ] Has a dry-run or read-only mode if it touches runtime state.
- [ ] Rollback documented (one paragraph in the PR/task is enough).
- [ ] Disaster-recovery impact stated: does rebuild-from-scratch still work?
      Does anything new need to ride in backups or the recovery pack?
- [ ] Docs updated in the same change (user-facing) or explicitly N/A.
- [ ] No secrets in git (gitleaks green; new secret files added to
      `docs/reference/secrets.md` inventory).
- [ ] CI green: `bash -n`, shellcheck, yamllint, compose config, gitleaks.
- [ ] The maintenance question answered: who/what breaks if this is
      forgotten about for a year?

### Part 3 — pointers and the AGENTS.md boundary
Link the backlog README's ground rules to this doc (replace the duplicated
list there with a link + the CI line), and reference it from
`docs/README.md` and `docs/reference/audit.md`.

**Division of labor with `/AGENTS.md` (exists since 2026-07-09; do not
duplicate it):** AGENTS.md is the *operational* contract for an implementing
agent in a fresh session — prime directives, scope rules, verification
commands, stop conditions. This document is the *design* constitution — what
to build, what to reject, and why. Rule of thumb: if a line tells an agent
how to behave during a session, it belongs in AGENTS.md; if it tells anyone
what the system should look like, it belongs here. When this doc lands,
update AGENTS.md's "Conventions" pointer (it already anticipates this file)
and check both for accidental overlap — each fact lives in exactly one of
the two.

## Affected files
- `docs/reference/architecture-principles.md` (new)
- `docs/README.md` (index entry, top of Reference section)
- `backlog/README.md` (ground rules section links here instead of duplicating)
- `AGENTS.md` (update its principles pointer; de-duplicate overlap per Part 3)
- `bin/domum-core` header comment (add one line pointing at the doc; keep the
  short in-code rules — they are load-bearing for sessions that only read
  the script)

## Testing plan
- Doc renders; links resolve both directions.
- Read-through test: every principle is one the repo already follows or has
  a backlog task moving toward it — the doc must describe reality plus
  agreed direction, not aspiration (if a principle has no supporting task or
  code, cut it or file the task).

## Rollback strategy
Docs only — revert.

## Dependencies
None. Every subsequent task benefits, so do it early.

## Risks
None operational. Main failure mode is bloat — hold the two-page line.

## Estimated complexity
Small (~6k tokens).

## Suggested order
End of Phase 0 / start of Phase 1 — before the big recovery tasks, so they
are written against the stated principles.
