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

AdGuard starts its setup UI on port `3000` before initialization. The compose
file exposes that UI through Traefik with `ADGUARD_WEB_PORT=3000`. During setup,
keep the admin web interface on port `3000`, or set `ADGUARD_WEB_PORT` to the
chosen port and re-run `sudo domum-core apply`. Configure AdGuard DNS to listen
on `0.0.0.0:53`.

Validate from domum-core or a Tailscale client:

```bash
nslookup budget.ladomum.com 100.121.26.52
tailscale status
```
