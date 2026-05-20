# domum-core

Self-updating home core services platform for Raspberry Pi (or any Debian/Ubuntu host).

This project is designed to be fully managed using one command:

    curl -fsSL https://raw.githubusercontent.com/jfrancolopez/domum-core/main/install.sh | sudo bash

Curl command:

- Installs Docker if missing
- Clones or updates the repository
- Initializes the host
- Applies the desired state

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

---

# DNS Setup

Cloudflare:
Traefik uses DNS-01 challenge. No ports need to be opened.

Certificates are automatically generated for:

    ha.ladomum.com
    status.ladomum.com
    portainer.ladomum.com

---

UniFi LAN DNS:

Create local A records:

    ha.ladomum.com -> 192.168.x.x
    status.ladomum.com -> 192.168.x.x
    portainer.ladomum.com -> 192.168.x.x

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
- Keep host config in /etc/domum.
- Keep secrets in /etc/domum/secrets.
- Use git for all service changes.
- Re-run curl anytime to converge state.


