# DNS plan for ladomum.com

Traefik serves HTTPS for services like:

- ha.ladomum.com
- budget.ladomum.com
- dns.ladomum.com
- z2m.ladomum.com
- speedtest.ladomum.com

Clients must resolve those names to the Traefik host.

## LAN

UniFi is the primary LAN DNS authority. Keep host records, CNAMEs, or wildcard
records there so local clients resolve service names to the domum-core LAN IP:

```text
*.ladomum.com -> 10.0.10.2
```

This is the reliable always-on path. LAN HTTPS must not depend on Tailscale or
AdGuard.

## Certificates

Traefik uses Let's Encrypt DNS-01 through Cloudflare. The ACME resolver uses
public recursive DNS servers so renewal does not depend on UniFi, AdGuard, or
Tailscale DNS.

## Tailscale

Tailscale is optional remote access. When enabled, point Tailscale split DNS for
`ladomum.com` at the domum-core Tailscale IP and configure AdGuard DNS rewrites:

```text
*.ladomum.com -> 100.121.26.52
ladomum.com   -> 100.121.26.52
```

Host Tailscale must run with `--accept-dns=false`. The Pi keeps its normal LAN
resolver path, and Tailscale never becomes a dependency for local HTTPS.
Tailscale SSH is disabled by default with `TAILSCALE_SSH=0`.
