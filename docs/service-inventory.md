# Live Service Inventory

This inventory is generated from the running `domum` Compose project on
`domum-core`. Homepage is the current directory; this document is the durable
operator reference.

| Category | Services |
|---|---|
| Home automation | Home Assistant, MariaDB, MQTT, Zigbee2MQTT, Z-Wave JS UI, Node-RED, ESPHome, Music Assistant |
| Monitoring | Homepage, Glance, Beszel Hub/Agent, Healthchecks, Dozzle, ntfy, Speedtest Tracker |
| Networking/security | Traefik, AdGuard Home, Vaultwarden, Tailscale |
| Applications | Actual Budget, Memos, Karakeep, FreshRSS, Stirling PDF, Obsidian Sync, IT-Tools |
| Supporting containers | Karakeep Chrome and Meilisearch |

## Criticality

- Critical: Traefik, Home Assistant, MQTT, Zigbee2MQTT, Z-Wave JS UI, MariaDB,
  AdGuard Home, Beszel Hub/Agent.
- Important: Node-RED, ESPHome, Vaultwarden, Actual Budget, ntfy, Healthchecks.
- Convenience: Homepage, Glance, Dozzle, Memos, Karakeep, FreshRSS, Stirling
  PDF, IT-Tools, Music Assistant, Obsidian Sync.

## Scheduled Work

| Job | Schedule | Healthchecks candidate |
|---|---|---|
| Backups | Daily 02:30 | Yes |
| Speed tests | 00:30 / 06:30 / 12:30 / 18:30 | Optional |
| Backup verification | Sunday 04:30 | Yes |
| Restore verification | First day of month 04:45 | Yes |
| Recovery pack | Sunday 03:30 | Yes |
| Daily checkup | Daily 07:30 | Optional |
| Weekly report | Sunday 08:00 | Optional |
| Update check | Daily 05:15 | No alert required |

Healthchecks ping URLs are secrets. Create checks in its authenticated UI and
store the resulting URLs under `/etc/domum-core/secrets` before integrating
them into existing jobs.

## Current Operational Finding

`domum-core-security-patches.service` failed on 2026-08-04 after unattended
upgrades found no eligible packages. Backups and daily checkup completed
successfully. This is not changed by the dashboard work and needs a separate
operations review.
