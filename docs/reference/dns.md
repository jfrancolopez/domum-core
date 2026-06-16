# DNS plan for ladomum.com

Traefik serves HTTPS for services like:
- ha.ladomum.com
- status.ladomum.com
- z2m.ladomum.com

Your clients must resolve those names to the Traefik host.

LAN options (pick one):
1) AdGuard Home (enable ENABLE_ADGUARD_HOME=1)
   - Create DNS rewrites or local records: *.ladomum.com -> Traefik LAN IP
2) Existing router DNS
   - Create host overrides or local DNS zone.

Tailscale options:
- Use Tailscale DNS settings (admin console) to set a split DNS rule for ladomum.com
- Point it to your AdGuard Home or directly to the Traefik host if you use host records.

Start simple:
- Use LAN DNS for home devices.
- Use Tailscale DNS for remote devices.
