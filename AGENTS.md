# AGENTS.md — instructions for any AI agent working in this repository

Read this completely before changing anything. Treat this session as brand
new: you have no prior conversation context. This repo, its `docs/`, and its
`backlog/` are the only memory that exists.

## What this repository is

Git-managed infrastructure for a **production** Raspberry Pi 5 home-automation
server: Home Assistant, MQTT, Zigbee/Z-Wave radios, MariaDB, Traefik, backups
to Hetzner and local NAS. A family relies on it daily. Mistakes here can break
a lived-in home or silently destroy the ability to recover from hardware
failure.

Key layout:
- `bin/domum-core` — the single CLI (deploy, backups, updates, checkup)
- `bin/domum-core-backup` — restic multi-target wrapper
- `compose/` — one compose fragment per service; the service catalog inside
  `bin/domum-core` (`service_catalog()`) is the single source of truth
- `config/*.example` — tracked; live `config/*.conf` — local-only, NEVER tracked
- `systemd/` — timer/service units; `docs/` — all documentation
- `backlog/` — the implementation roadmap; `backlog/README.md` is its index

## Prime directives — never violate

1. **Never delete or overwrite user data, live config, secrets, or backups.**
   No `rm -rf`, no `git clean`, no resetting files you did not create.
2. **Secrets never touch git.** Never commit `config/domum.conf`,
   `config/domum-backup.conf`, key files, passwords, tokens, or anything
   under a `data/` directory. If you find a secret in the tree, stop and
   report it — do not "fix" it by rewriting history.
3. **This checkout is not the production host.** Do not run
   `domum-core apply`, `docker compose up`, or anything that starts/stops
   services unless the task explicitly says to and you are on the Pi.
   Changes reach production via: commit → push → (on the Pi)
   `sudo domum-core update` → re-run installer/units if `bin/` or `systemd/`
   changed → `sudo domum-core apply` → `sudo domum-core checkup`.
4. **The OS is disposable; the data and repo are not.** Never design or
   document anything that depends on preserving an old root filesystem.
   Recovery is always: fresh Debian → bootstrap → restore.
5. **Simplest reliable change wins.** Standard Debian tools, plain bash,
   no new dependencies without written justification in the task. Do not
   rewrite working code for style. Deleting an unused feature beats
   improving it.

## Working a backlog task

1. Read the ENTIRE task file first, including rollback and testing sections.
2. **Verify the task's premise against the current code before editing.**
   The repo may have moved since the task was written (`git log --oneline -15`).
   If the work is already done, update its status in `backlog/README.md`
   instead of redoing it. If the premise contradicts what you see, stop and
   say so — do not force the plan.
3. **Stay in scope.** Touch only the files the task lists (plus docs it
   requires). If you discover a new bug, gap, or simplification while
   working: write a NEW `backlog/task-NN-<slug>.md` (next free number) and
   continue. Never widen the current change to absorb it, and never leave a
   finding only in your chat reply.
4. New backlog tasks must be self-contained for a future agent with zero
   context: objective, background, why it exists, current behavior, desired
   behavior, implementation plan, affected files, testing plan, rollback,
   dependencies, risks, complexity, suggested order. **Record decisions and
   rejected alternatives with their reasons** — future sessions must not
   re-litigate them.
5. Follow the task's own testing plan. If a test requires the production
   host and you are not on it, say which steps remain untested — never claim
   verification you did not perform.

## Verification before every commit

```bash
bash -n bin/domum-core bin/domum-core-backup install.sh
shellcheck bin/domum bin/domum-core bin/domum-core-backup install.sh
yamllint -c .yamllint.yml .
tests/gitleaks-tracked.sh       # production checkout safe: scans tracked files only
git diff --cached --name-only   # confirm: no live config, no secrets, no data dirs
```

CI (`.github/workflows/validate.yml`) also renders all compose files and runs
gitleaks — do not merge red CI.

## Conventions

- Commits: `<area>: <imperative summary>` — e.g. `backup: isolate per-target
  failures`, `docs: rewrite storage runbook`. One logical change per commit.
- When a task is completed, mark it `✅ done (<commit>)` in
  `backlog/README.md`.
- User-facing changes update `docs/` in the same commit; new docs get an
  entry in `docs/README.md`.
- Design philosophy and the per-change acceptance checklist:
  `docs/reference/architecture-principles.md`. Run every change through its
  checklist before committing.

## Stop and ask the operator when

- an action would delete/move data or touch anything under
  `/etc/domum-core/secrets`;
- the task requires the production host (SSH, live containers, real backups);
- the task's premise no longer matches the repository;
- you are about to add a dependency, service, or abstraction the task does
  not explicitly call for.
