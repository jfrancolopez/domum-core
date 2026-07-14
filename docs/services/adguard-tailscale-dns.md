# AdGuard + Tailscale DNS

AdGuard Home on domum-core is optional. Its only intended role is split DNS for
Tailscale clients when away from home. It is not the primary LAN resolver.

The normal LAN path is:

- UniFi DNS answers `*.ladomum.com` with the domum-core LAN IP.
- Clients connect directly to Traefik on the LAN.
- Traefik serves Let's Encrypt certificates for HTTPS.

The optional Tailscale path is:

- Tailscale routes remote clients to the domum-core Tailscale IP.
- Tailscale split DNS for `ladomum.com` points at AdGuard on domum-core.
- AdGuard rewrites `*.ladomum.com` to the domum-core Tailscale IP.

Recommended AdGuard DNS rewrites:

```text
*.ladomum.com -> 100.121.26.52
ladomum.com   -> 100.121.26.52
```

Keep UniFi LAN DNS as:

```text
*.ladomum.com -> 10.0.10.2
```

## Git-managed behavior

The repo manages the safe, repeatable parts:

- AdGuard is exposed to Traefik as `dns.<domain>`.
- Before AdGuard is initialized, Traefik targets the setup UI on port `3000`.
- After AdGuard writes `AdGuardHome.yaml`, `domum-core` detects the configured
  web port and exports it to compose. A later `sudo domum-core apply` updates
  Traefik if AdGuard moved the UI to port `80`.
- `domum-core checkup` warns when AdGuard's detected web port and Traefik's
  current backend label differ.

Do not commit `compose/networking/adguard/conf/AdGuardHome.yaml`. It contains
local runtime state and password hashes.

## One-time setup after rebuild

These steps are intentionally manual because they include local credentials or
external DNS-control-plane state:

- Open `https://dns.ladomum.com/` and create the AdGuard admin user.
- Configure the AdGuard web interface. Port `80` is fine after setup.
- Configure AdGuard DNS to listen on `0.0.0.0:53`.
- Add the DNS rewrites above for Tailscale clients.
- Re-run `sudo domum-core apply` after finishing setup so Traefik targets the
  post-setup web port.
- In the Tailscale admin console, keep split DNS for `ladomum.com` pointed at
  the domum-core Tailscale IP.

Validate from domum-core or a Tailscale client:

```bash
nslookup budget.ladomum.com 100.121.26.52
tailscale status
```
