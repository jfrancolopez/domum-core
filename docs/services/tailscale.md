# Tailscale

Tailscale is optional remote access for domum-core. It is not part of the LAN
HTTPS path.

When `ENABLE_TAILSCALE=1`, `sudo domum-core init` ensures the host `tailscaled`
service is installed and enabled. Tailscale is deliberately host-managed instead
of Docker-managed because it owns host networking and should keep working even
if Docker is unhealthy.

Use:

```bash
sudo tailscale up --accept-dns=false
```

The `--accept-dns=false` setting is required for this host. UniFi remains the LAN
DNS authority, and Traefik certificate renewal uses Cloudflare DNS-01 with public
recursive resolvers. Tailscale DNS must not become a dependency for local HTTPS.

After disaster recovery, re-authenticate Tailscale. Node keys are not backed up
because they are re-issuable.
