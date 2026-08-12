# Install on Raspberry Pi 5 NVMe

This is the base-host install path for the production domum-core machine:
Raspberry Pi 5, official PCIe/NVMe HAT, Debian 13 Lite arm64, Zigbee and Z-Wave
USB radios, and Docker-managed services under `/opt/domum-core`.

For disaster recovery, use this page only for the base OS. Restore service data
with [Disaster recovery](../backups/disaster-recovery.md). Backups are restic
based; do not set up rsync/cron mirror backups from old notes. See
[Backups overview](../backups/overview.md).

## 1. Flash Debian 13 Lite

Use Raspberry Pi Imager:

- OS: Debian 13 Lite, arm64
- Target: NVMe drive on the PCIe HAT
- Enable SSH with your operator public key
- Set hostname, locale, timezone, and Wi-Fi only if Ethernet is unavailable

Boot the Pi from the NVMe. If this is a rebuild, do not restore `/opt/domum-core`
before running the installer; `install.sh` must create or update the git checkout
first.

## 2. Set NVMe Boot Order

Update EEPROM and set NVMe first, then SD, then USB:

```bash
sudo apt-get update -y
sudo apt-get install -y rpi-eeprom
sudo rpi-eeprom-update -a
sudo rpi-eeprom-config --edit
```

Set:

```text
BOOT_ORDER=0xf416
```

Reboot and confirm the Pi boots from NVMe.

```bash
sudo reboot
lsblk
```

## 3. Base OS

```bash
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y
sudo timedatectl set-timezone America/New_York
sudo hostnamectl set-hostname domum-core
sudo reboot
```

## 4. Security Baseline

Install and test operator SSH keys before disabling password login:
[Operator SSH access](operator-ssh-access.md).

Harden SSH:

```bash
sudoedit /etc/ssh/sshd_config
```

Required settings:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Validate and restart:

```bash
sudo sshd -t
sudo systemctl restart ssh
```

Install firewall and fail2ban:

```bash
sudo apt-get install -y ufw fail2ban
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 9090/tcp
sudo ufw enable
sudo systemctl enable --now fail2ban
```

Docker-published ports can bypass host `ufw` rules. Do not expose unauthenticated
services just because `ufw` is enabled; MQTT authentication is mandatory because
port `1883` is published by Docker. See [MQTT](../services/mqtt.md).

## 5. Install domum-core

```bash
curl -fsSL https://raw.githubusercontent.com/jfrancolopez/domum-core/main/install.sh | sudo bash
```

The installer:

- installs prerequisite packages for fetching the repo;
- clones or updates `/opt/domum-core`;
- links `/usr/local/bin/domum-core`, `domum-core-backup`, and `domum`;
- creates `/etc/domum-core/secrets`, `/var/lib/domum-core`, and
  `/var/log/domum-core`;
- creates missing live config files from tracked examples;
- does not overwrite live config;
- does not run `init` or `apply` automatically.

Root-run update flows fetch over HTTPS. If you push from the Pi, keep SSH for
push only:

```bash
sudo git -C /opt/domum-core remote set-url origin https://github.com/jfrancolopez/domum-core.git
sudo git -C /opt/domum-core remote set-url --push origin git@github.com:jfrancolopez/domum-core.git
```

## 6. Configure And Converge

Review and edit the live config:

```bash
sudo domum-core configure --show
sudoedit /opt/domum-core/config/domum.conf
sudoedit /opt/domum-core/config/domum-backup.conf
sudo domum-core configure --validate
```

Initialize the host, apply services, then verify:

```bash
sudo domum-core init
sudo domum-core apply
sudo domum-core checkup
git -C /opt/domum-core status --short
```

`domum-core init` converges the mechanical host state: Docker if missing, the
standard backup/recovery utility packages, bounded Docker json-file logs, Docker
`userland-proxy=false`, state directories, secrets directory, config examples,
and optional host Tailscale. If it creates `/etc/docker/daemon.json` on a running
host, it asks before restarting Docker because that restarts containers.

`init` prints the remaining operator checklist instead of applying it for you:
timezone/hostname, SSH hardening, firewall/fail2ban, and maintenance timer
enablement. Those steps can lock out a headless Pi or require local judgment.

See [First run](first-run.md) for the normal command sequence and config safety
rules.

## 7. Host-Specific One-Offs

Create the Traefik dashboard users file before exposing the dashboard:

```bash
sudo apt-get install -y apache2-utils
sudo install -d -m 0700 /etc/domum-core/secrets
sudo htpasswd -nbB admin 'CHANGE_ME_LONG_RANDOM_PASSWORD' \
  | sudo tee /etc/domum-core/secrets/traefik_dashboard_users >/dev/null
sudo chmod 600 /etc/domum-core/secrets/traefik_dashboard_users
```

Home Assistant needs a local `secrets.yaml` before first start when the tracked
configuration references `!secret` values. See
[Home Assistant](../services/home-assistant.md#first-run-secrets).

If Cockpit is reverse-proxied through Traefik, allow the proxied origin in
`/etc/cockpit/cockpit.conf`:

```ini
[WebService]
Origins = https://cockpit.example.com wss://cockpit.example.com https://10.0.10.2:9090
ProtocolHeader = X-Forwarded-Proto
ForwardedForHeader = X-Forwarded-For
```

Restart Cockpit after editing:

```bash
sudo systemctl restart cockpit.socket
```

## 8. Backups And Timers

Configure backups before trusting the rebuild:

```bash
sudo domum-core backups run --dry-run
sudo domum-core backups run
sudo domum-core schedule install-maintenance
```

Enable only the timers you want. See [Maintenance timers](../operations/maintenance-timers.md).
