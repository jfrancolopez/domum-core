# Cloudflare DNS-01 token

Create an API token in Cloudflare with:
- Zone:DNS:Edit for your zone (ladomum.com)

On the host, create:
- /etc/domum-core/secrets/cloudflare_api_token

Then run:
- sudo domum apply
