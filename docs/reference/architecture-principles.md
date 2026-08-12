# Architecture principles & feature acceptance checklist

The permanent design philosophy of domum-core, plus the checklist every
change must satisfy before merging. Guardrails, not a law book.

This is the *design* constitution — what to build, what to reject, and why.
The *operational* contract for implementing agents (scope rules, verification
commands, stop conditions) lives in [/AGENTS.md](../../AGENTS.md); each fact
lives in exactly one of the two documents.

## Principles

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

## Feature acceptance checklist

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
- [ ] No secrets in git (`tests/gitleaks-tracked.sh` green; new secret files added to the
      [secrets inventory](secrets.md)).
- [ ] CI green: `bash -n`, shellcheck, yamllint, compose config, gitleaks.
- [ ] The maintenance question answered: who/what breaks if this is
      forgotten about for a year?

## Pointers

- Implementation roadmap and per-task ground rules:
  [backlog/README.md](../../backlog/README.md)
- Agent execution contract: [/AGENTS.md](../../AGENTS.md)
- Repository history and audit trail: [audit.md](audit.md)
