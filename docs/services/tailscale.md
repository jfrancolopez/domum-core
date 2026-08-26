# Tailscale

Tailscale is optional remote access for domum-core. It is not part of the LAN
HTTPS path.

When `ENABLE_TAILSCALE=1`, `sudo domum-core init` ensures the host `tailscaled`
service is installed and enabled. Tailscale is deliberately host-managed instead
of Docker-managed because it owns host networking and should keep working even
if Docker is unhealthy.

Use:

```bash
sudo tailscale up --accept-dns=false --ssh=false --snat-subnet-routes=false
```

The `--accept-dns=false` setting is required for this host. UniFi remains the LAN
DNS authority, and Traefik certificate renewal uses Cloudflare DNS-01 with public
recursive resolvers. Tailscale DNS must not become a dependency for local HTTPS.
`--ssh=false` keeps Tailscale SSH disabled unless `TAILSCALE_SSH=1` is set in
`config/domum.conf`.

`--snat-subnet-routes=false` preserves real Tailscale client addresses when
Docker forwards published HTTPS ports to Traefik. Without it, Tailscale's
postrouting masquerade can replace the client address with Docker's bridge
gateway and make Traefik deny a valid tailnet client. Domum-core does not use
this Pi as a subnet router or exit node. Do not add advertised routes without a
separate return-routing design that revisits this setting.
`domum-core init` and `apply` refuse to change the setting if advertised routes,
an exit-node role, or unreadable Tailscale state prevents confirming this
host-only role.

After disaster recovery, re-authenticate Tailscale. Node keys are not backed up
because they are re-issuable.
