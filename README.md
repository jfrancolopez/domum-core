# domum-core

Self-updating home core services platform for Raspberry Pi (or any Debian/Ubuntu host).

This project is designed to be fully managed using one command:

    curl -fsSL https://raw.githubusercontent.com/jfrancolopez/domum-core/main/install.sh | sudo bash

Curl command:

- Installs Docker if missing
- Clones or updates the repository
- Installs the `domum-core` CLI

It does **not** run `init` or `apply` automatically on re-install. Review config
and run those explicitly.

---

# Architecture Philosophy

- Git = source of truth
- Host config and secrets live outside the repo
- No inbound ports required
- TLS via Cloudflare DNS-01
- LAN + Tailscale DNS resolution
- Simple systemd timers for scheduling

---

# Directory Layout

Application Code:
    /opt/domum-core
Managed by git. Never edit directly on the host.

Host Configuration:
    /opt/domum-core/domum.conf

Secrets:
    /etc/domum-core/secrets/


---

# First-Time Setup (New Host)

1. Create secrets directory:

    sudo mkdir -p /etc/domum-core/secrets

2. Add your Cloudflare API token:

    sudo nano /etc/domum-core/secrets/cloudflare_api_token
    sudo chmod 600 /etc/domum-core/secrets/cloudflare_api_token

Required Cloudflare permissions:
- Zone:DNS:Edit
- Zone:Zone:Read

3. Run:

    curl -fsSL https://raw.githubusercontent.com/jfrancolopez/domum-core/main/install.sh | sudo bash


Re-running the same command updates everything.

Useful docs:

- `docs/CONFIGURE.md`
- `docs/SETUP-BACKUPS.md`
- `docs/SETUP-HETZNER-BACKUP.md`
- `docs/RECOVERY-PACK-EMAIL.md`
- `docs/VAULTWARDEN.md`
- `docs/OBSIDIAN-SYNC.md`
- `docs/SECURITY-PATCHES.md`
- `docs/ADGUARD-TAILSCALE-DNS.md`
- `docs/MIGRATION-REMOVED-SERVICES.md`

---

# Configuration File

Host configuration lives in:

    /opt/domum-core/domum.conf

Example:

    DOMUM_DOMAIN="ladomum.com"
    DOMUM_EMAIL="you@email.com"

    ENABLE_TRAEFIK=1
    ENABLE_HOME_ASSISTANT=1
    ENABLE_MQTT=1
    ENABLE_ZIGBEE2MQTT=1
    ENABLE_UPTIME_KUMA=1
    ENABLE_PORTAINER=1

Night scheduling:

    ENABLE_NIGHT_PROFILE=1
    NIGHT_UP_TIME="23:00"
    NIGHT_DOWN_TIME="07:00"

Backup / recovery / update settings live in the overlay file
`config/domum-backup.conf` (copied from `.example` on `init`).

---

# Management CLI (`domum-core`)

The CLI was consolidated into a single command, `domum-core`
(`/usr/local/bin/domum-core`). `domum` is kept as a back-compat shim.

    sudo domum-core init          # install Docker, dirs, configs
    sudo domum-core apply         # converge compose state
    sudo domum-core status --counts
    sudo domum-core checkup       # health report (CRITICAL/WARNING/HEALTHY/ACTION)
    sudo domum-core backups run   # restic backup (targets disabled by default)
    sudo domum-core recovery-pack create
    sudo domum-core updates check

Production operating model — backups, per-service backups, AGE-encrypted
recovery packs, a cautious class-based update model, and systemd maintenance
timers — is documented here:

- `docs/CLI-CHEATSHEET.md` — every command at a glance
- `docs/CHECKUP.md` — health checks
- `docs/SETUP-BACKUPS.md` — restic multi-target backups
- `docs/ACTUAL-BUDGET-BACKUP.md`, `docs/HOME-ASSISTANT-BACKUP.md`
- `docs/UPDATES.md` — the update model
- `docs/DISASTER-RECOVERY.md` — full rebuild runbook
- `docs/SECRETS.md` — secrets + AGE keypair
- `docs/AUDIT.md` — repo audit + bugs fixed

Backups, timers, the AGE keypair, and email are all **off until you set them
up** — see the docs above. Install (but do not enable) the maintenance timers:

    sudo domum-core schedule install-maintenance

---

# DNS Setup

Cloudflare:
Traefik uses DNS-01 challenge. No ports need to be opened.

Certificates are automatically generated for:

    ha.ladomum.com
    status.ladomum.com
    actual.ladomum.com
    vault.ladomum.com      # optional
    obsidian.ladomum.com   # optional

---

UniFi LAN DNS:

Create local A records:

    ha.ladomum.com -> 192.168.x.x
    status.ladomum.com -> 192.168.x.x
    actual.ladomum.com -> 192.168.x.x

If wildcard supported:

    *.ladomum.com -> 192.168.x.x

---

Tailscale Remote DNS:

In Tailscale admin console:

DNS → Split DNS

Domain:
    ladomum.com

Nameserver:
    192.168.x.x

Now internal names resolve both locally and remotely.

---

# Notes

- Never edit files inside /opt/domum-core directly.
- Keep host config in /opt/domum-core/config/domum.conf.
- Keep secrets in /etc/domum-core/secrets/.
- Use git for all service changes.
- Re-run curl anytime to converge state.
- See `docs/CLI-CHEATSHEET.md` for the full `domum-core` command surface.
