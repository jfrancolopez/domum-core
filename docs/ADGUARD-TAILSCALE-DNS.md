# AdGuard + Tailscale DNS

AdGuard Home on domum-core is not the primary home DNS server. Its role is remote DNS for
Tailscale clients: Split DNS, VPN name resolution, and controlled filtering when away from
home.

Keep the home LAN router or existing DNS path as the primary resolver unless you
intentionally migrate that responsibility. For Tailscale, point the tailnet DNS settings at
the domum-core Tailscale IP and configure split domains for internal names.

Validate from a Tailscale client:

```bash
nslookup homeassistant.ladomum.com <domum-core-tailscale-ip>
tailscale status
```
