# Task 30 — Compose + gitignore hygiene batch

## Objective
One batch of small, verified inconsistencies in the compose layer and
`.gitignore` — none urgent alone, together they remove a class of "wait, why
is this different here?" traps.

## Verified items

### 1. `domum-data` network declared inconsistently
`compose/automation/home-assistant.yml` declares:
```yaml
networks:
  domum-data:
    name: domum-data
    driver: bridge      # NOT external — every other file says external: true
```
All other fragments (mariadb, actual-budget, vaultwarden, obsidian-sync,
music-assistant, zwave-js-ui) declare it `external: true`, and
`ensure_networks()` pre-creates it. The merged config's behavior depends on
file order — fragile. Fix: `external: true` in home-assistant.yml like the
rest. Verify with `docker compose ... config` before/after (expect the
rendered network to become external; no container recreation should result —
confirm with `apply` being a no-op).

### 2. Hardcoded personal email in two Traefik files
- `compose/proxy/traefik.yml`: `- DOMUM_EMAIL=jfranco.lopez@outlook.com`
  (while `export_env_for_compose` already exports `DOMUM_EMAIL` — the
  hardcode overrides the config value; should be `${DOMUM_EMAIL}`).
- `compose/proxy/traefik/traefik.yml` (static config): `email: "jfranco.lopez@outlook.com"`
  under the ACME resolver. Traefik's file provider does not interpolate env
  vars in static config the way compose does — options: keep it hardcoded
  but documented (acceptable: ACME email is not a secret, but it IS
  site-specific in a public repo), or drop the file's `certificatesResolvers`
  block in favor of CLI flags (see item 3). Decide with item 3.

### 3. Traefik static config is defined TWICE (file + CLI flags)
The container both mounts `/etc/traefik/traefik.yml` (static config file)
AND passes `command:` flags (`--api.dashboard`, `--entrypoints...`,
`--providers...`). Traefik reads both with CLI taking per-key precedence —
but the two sets have already drifted: the **file** defines the web→websecure
redirect and the `cf` ACME resolver; the **CLI flags** define neither. A
future editor changing one copy will silently not change effective behavior
(or worse, half-change it). Fix: pick ONE source. Recommendation: the file
(it holds the redirect + ACME, i.e. the important parts); shrink `command:`
to nothing (or only `--configFile=/etc/traefik/traefik.yml` for
explicitness). Before landing, diff effective config via the Traefik
dashboard or debug log on the host, since precedence subtleties are easy to
get wrong. Test: TLS certs still issue, HTTP still redirects, dashboard auth
still works.

### 4. `privileged: true` where a device mapping already suffices
- `zwave-js-ui`: has the specific `devices:` mapping AND `privileged: true`.
  Privileged is redundant for serial access — remove, keep `devices:`.
- `esphome`: privileged with no device mapping (USB flashing is done via the
  browser/OTA these days). Try removing; if a use case surfaces (USB flash
  from the Pi), map the specific device instead.
- `homeassistant`: privileged commonly cargo-culted; HA needs it only for
  host Bluetooth/usb integrations. Verify on the host whether any HA
  integration uses host hardware (Bluetooth?); if none, remove; if yes,
  document WHY in a comment. Do HA last and separately — one service per
  apply, rollback = re-add the line.

### 5. `.gitignore` gaps for runtime data dirs (stopgap until task 17)
Verified NOT ignored (untracked-noise + `git clean -fdx` hazard on the Pi):
```
compose/networking/adguard/        (work/ + conf/)
compose/automation/zwave-js-ui/store/
compose/automation/esphome/        (runtime state mixed with configs)
compose/automation/music-assistant/
```
Add explicit lines for these four (esphome needs care: its *.yaml device
configs may be worth tracking — check what lives there on the Pi; ignore
selectively: `.esphome/`, `secrets.yaml` pattern, etc.). Also add
`compose/automation/mqtt/log/` if not covered. This is a 10-line stopgap
that makes task 17 (data out of tree) less urgent, not a replacement for it.

### 6. `depends_on: mariadb: service_healthy` breaks HA-without-MariaDB
`home-assistant.yml` hard-depends on the `mariadb` service. With
`ENABLE_HOME_ASSISTANT=1, ENABLE_MARIADB=0`, the merged compose config is
invalid (undefined service). Today both are enabled, so it is latent. Fix
cheaply: document in the compose file + `config/domum.conf.example` that HA
requires MariaDB enabled (recorder lives there anyway), OR make the
dependency `required: false` (compose ≥ 2.20 supports it). Prefer the
comment — the dependency is real in this deployment.

## Affected files
- `compose/automation/home-assistant.yml`, `compose/proxy/traefik.yml`,
  `compose/proxy/traefik/traefik.yml`, `compose/automation/zwave-js-ui.yml`,
  `compose/automation/esphome.yml`
- `.gitignore`
- `config/domum.conf.example` (HA/MariaDB note)

## Testing plan
- CI compose-validate green.
- On host, after each sub-item: `sudo domum-core apply` then
  `sudo domum-core checkup` — expect zero recreations except the service
  being touched.
- Item 3 additionally: issue a cert renewal dry-check (`docker logs traefik`
  clean), curl the HTTP→HTTPS redirect, dashboard reachable.
- Item 5: `git status` on the Pi shows a clean tree.

## Rollback strategy
Each item is one-line-ish and independently revertible. Land as separate
commits within one PR so a problem item can be reverted alone.

## Dependencies
None. Item 5 is superseded eventually by task 17 (fine — cheap insurance).

## Risks
Item 3 (Traefik) is the only medium-risk one — TLS issuance is involved;
mitigated by the effective-config diff and by doing it in daylight, not
before a trip. Others are low.

## Estimated complexity
Small–medium (~10k tokens).

## Suggested order
Hygiene phase. Items 1, 2, 4 (zwave/esphome), 5, 6 are agent-safe; item 3 and
HA-privileged want the operator around.
