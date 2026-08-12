# Beszel

Beszel is the detailed Domum monitoring UI at
`https://beszel.${DOMUM_DOMAIN}`. The local agent monitors the Pi, selected
network interfaces, NVMe SMART data, Docker lifecycle/CPU/network data, and
selected systemd services.

## Enable the Hub

Beszel is disabled by default. Enable it with `ENABLE_BESZEL`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The hub is exposed as `https://beszel.${DOMUM_DOMAIN}` through Traefik. Add a
matching DNS CNAME before using it from the LAN.

## First Login

Open the hub and create the first admin account. Keep the credentials in
Vaultwarden.

## Local Agent

The agent uses Unix-socket mode and does not publish port 45876. In the Beszel
system configuration, set Host / IP to `/beszel_socket/beszel.sock`.

Its public key and token are root-owned files under `/etc/domum-core/secrets`.
They are mounted read-only through `KEY_FILE` and `TOKEN_FILE`; never put them
in Compose, Git, or the Beszel UI notes.

The agent has read-only Docker socket access, `/dev/nvme0`, and the two SMART
capabilities required by `smartctl`. Docker currently reports `0B / 0B` memory
for every container, so per-container memory metrics are unavailable until the
Docker/cgroup reporting issue is resolved. CPU, lifecycle, and network metrics
remain available.

Configure these conservative alerts in the authenticated Beszel UI: host
unavailable; root filesystem warning at 80% and critical at 90%; sustained host
memory at 90%; sustained CPU temperature at 80 C; sustained abnormal load; and
critical automation containers stopped unexpectedly. SMART failures notify
automatically once a Beszel notification channel exists.

## Data and Backups

Hub state lives at:

```text
compose/monitoring/beszel/data
```

Beszel uses PocketBase/SQLite-style local state. `domum-core backups run`
includes Beszel when `BACKUP_BESZEL=1`; the service backup briefly pauses the
container while tarring the directory so database files are consistent.

## Updates

Beszel participates in the normal container update workflow with
`BESZEL_AUTO_UPDATE` and `BESZEL_UPDATE_DELAY_DAYS`. It defaults to manual
updates because it is stateful monitoring infrastructure.

## Glance Source Review

Beszel is the selected first external Hosting source for Glance, but Glance does
not consume Beszel metrics yet. Public upstream review found authenticated
PocketBase collections for systems and stats plus a readonly role, but no stable
OpenAPI or separately versioned Beszel API contract. Do not build a Glance widget
until the Pi review verifies a dedicated readonly credential or token, approved
host aliases/system IDs, allowed fields, cache/stale behavior, and failure modes.

Do not reuse Homepage's Beszel superuser credentials for Glance unless the
operator explicitly accepts that risk and no narrower read path exists.

If a dedicated Glance Beszel user exists, store it only on the Pi in:

```text
/etc/domum-core/secrets/glance-beszel.env
```

Use `config/glance-beszel.env.example` as the format. The system ID values must
come from the live Beszel API/UI and should identify only the two approved active
systems.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `beszel.${DOMUM_DOMAIN}`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs beszel` or Dozzle.
