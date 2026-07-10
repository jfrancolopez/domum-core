# Task 37 — CRITICAL: configure wizard eats its own catalog as answers (silently disables services)

## Objective
Fix the stdin conflict in `configure_wizard()` that makes the interactive
wizard consume service-catalog lines as if they were the operator's typed
answers — writing `ENABLE_<SVC>=0` for production services without the
operator ever seeing a prompt. Until fixed, the wizard is UNSAFE to run.

## The bug (verified live, 2026-07-10, production Pi)
`configure_wizard()` in `bin/domum-core`:

```bash
while IFS='|' read -r name enable_var _rest; do
  set_conf_key "$CFG_FILE" "$enable_var" "$(ask_bool "  $name" "${!enable_var:-0}")"
done < <(service_catalog)
```

The `< <(service_catalog)` redirect applies to the **whole loop body**, so
`ask_bool`'s `read -r -p` reads its "answer" from the catalog stream, not
the terminal: the loop reads row N as the service, ask_bool swallows row
N+1 as the answer. Since a catalog row is never the string `1`, `ask_bool`
returns 0 → **every other service gets ENABLE_*=0 written**, half the
catalog is never processed at all, and no prompt is shown (read suppresses
the prompt when stdin is not a tty).

The same pattern repeats in the "-- Updates (per app) --" section
(`done < <(enabled_services)` with two reads inside).

### Observed fallout on the Pi (2026-07-10 ~15:42)
- Wizard run 1 printed the `-- Services --` header then jumped straight to
  `-- Backup --`; afterwards `enabled_services` had shrunk to
  {traefik, mqtt, nodered, adguard-home}. ENABLE_MARIADB=0 while
  ENABLE_HOME_ASSISTANT stayed 1 → `apply` failed with
  `service "homeassistant" depends on undefined service "mariadb"`.
- Wizard run 2 re-scrambled to a different subset ({home-assistant,
  esphome} visible in its updates section).
- Recovery: the wizard's own pre-run backup
  (`configure_backup_current` → `/var/lib/domum-core/config-backups/<ts>/`)
  restored the pre-wizard config. That safety net worked — keep it.

## Fix
Use a separate file descriptor for every loop whose body prompts the user:

```bash
while IFS='|' read -r -u3 name enable_var _rest; do
  set_conf_key "$CFG_FILE" "$enable_var" "$(ask_bool "  $name" "${!enable_var:-0}")"
done 3< <(service_catalog)
```

Apply the same `-u3` / `3< <(...)` pattern to the updates-policy loop (and
audit every other `while read` in `configure_wizard` for prompts inside the
body; the non-interactive loops elsewhere in the CLI are fine as-is).

Additionally (cheap hardening, same session):
1. `ask`/`ask_bool`: fail loudly if stdin is not a tty
   (`[[ -t 0 ]] || die "configure wizard needs an interactive terminal"`) —
   turns any future stdin regression into an immediate error instead of
   silent config corruption.
2. After the wizard writes everything, print a diff summary against the
   pre-run backup (`diff -u <backup>/domum.conf "$CFG_FILE"` trimmed) so the
   operator sees exactly which keys changed before running apply.

## Affected files
- `bin/domum-core` — `configure_wizard()`, `ask()`, `ask_bool()`

## Testing plan
- Interactive: run the wizard on a scratch config (`CFG_FILE=/tmp/x.conf
  BACKUP_CFG_FILE=/tmp/y.conf DOMUM_DIR=... bin/domum-core configure`);
  every service prompt appears, one per catalog row; pressing Enter
  everywhere produces a **zero-diff** config (acceptance test).
- Pipe test: `echo | domum-core configure` must die with the tty error, not
  write anything.
- `bash -n` + shellcheck.

## Rollback strategy
Revert the commit; the wizard returns to broken-but-known state (and docs
should then say "do not use the wizard" until re-fixed).

## Dependencies
None. **Do this before anyone runs `configure` again** — until then, edit
`config/domum.conf` / `config/domum-backup.conf` directly with an editor.

## Risks
Low — the fix is mechanical FD hygiene; the acceptance test (Enter-through
⇒ zero diff) proves no behavior change beyond the fix.

## Estimated complexity
Small (~6k tokens).

## Suggested order
Immediately — top of the queue, ahead of everything else open.
