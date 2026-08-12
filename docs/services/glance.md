# Glance

Glance is the complementary daily overview at `https://dash.${DOMUM_DOMAIN}`.
It provides portal links and curated technology feeds, not a second service
directory or a replacement for Beszel's historical metrics.

## Enable the Service

Glance is disabled by default. Enable it with `ENABLE_GLANCE`:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://dash.${DOMUM_DOMAIN}` through Traefik.

## Configuration

The tracked config lives at:

```text
compose/monitoring/glance/glance.yaml
compose/monitoring/glance/pages/
```

`glance.yaml` owns the global server, branding, theme, and page order. Individual
pages live under `pages/` and are included with Glance `v0.8.5` `$include`
syntax. Validate the complete include tree with:

```bash
tests/glance-config-validate.sh
```

Keep secrets out of this file. If a future widget needs a token, store the token
under `/etc/domum-core/secrets` and pass it through a file-backed environment
variable instead of committing it.

The optional Beszel integration env file is:

```text
/etc/domum-core/secrets/glance-beszel.env
```

Use `config/glance-beszel.env.example` as the format. The file is loaded only if
it exists and should be mode `0600`, owner `root:root`. It currently prepares
credential and two-system metadata for task 54; it does not render Beszel metrics
until the source review is complete.

Do not create separate `glance_beszel_username` or `glance_beszel_password`
files. If those files were created from an earlier draft, remove them after the
combined env file is populated:

```bash
sudo rm -f /etc/domum-core/secrets/glance_beszel_username /etc/domum-core/secrets/glance_beszel_password
```

Glance has no Docker socket or host filesystem mounts. Do not present its
container-local values as Raspberry Pi metrics; use Beszel for those values.

## Private Access Preparation

`GLANCE_PRIVATE_ACCESS=0` leaves the current access policy unchanged. Task 49
will attach the approved Traefik middleware and then require both:

```bash
GLANCE_PRIVATE_ACCESS=1
DOMUM_GLANCE_LAN_CIDR="your-lan-cidr"
```

Keep the real CIDR only in `config/domum.conf`; it is private topology and must
not be committed. `sudo domum-core configure --validate` rejects blank or
malformed CIDRs when private access is enabled. When enabled, Traefik permits
only that LAN CIDR and Tailscale's CGNAT range. Test LAN, Tailscale, external
denial, and the Homepage embed after every access-policy change.

Docker must keep `userland-proxy=false` in `/etc/docker/daemon.json`; otherwise
Traefik can see Docker's proxy/NAT source instead of the real Tailscale client
and deny valid tailnet traffic. `domum-core init` converges that daemon setting
for rebuilds, but changing it on a live host requires a Docker restart.

## Data and Backups

Glance has no runtime data in this deployment. Its dashboard config is tracked in
git, so recovery is a rebuild from git followed by `sudo domum-core apply`.

## Updates

Glance is pinned by `GLANCE_IMAGE`, currently `glanceapp/glance:v0.8.5`.
`GLANCE_AUTO_UPDATE=0` is the safe default: review upstream release notes,
change the pin deliberately, run `tests/glance-config-validate.sh`, deploy, and
confirm the running footer/version before accepting a bump.

The validation script uses Glance's own `config:validate` command with dummy
non-secret environment values. It proves the active config parses for the pinned
release; it does not contact live APIs or prove widget data is correct.

## Adding Pages and Widgets

Add a page only after its capability-matrix rows are approved. Put the page in
`compose/monitoring/glance/pages/`, then include it from `glance.yaml` with:

```yaml
pages:
  - $include: pages/new-page.yml
```

Do not add placeholder pages or invented widget types. Community examples must
be copied into the repository only after source, request, credential, cache,
privacy, and failure behavior review.

## Current Pages

- Home: native search, month calendar, three clocks, Durham weather, compact
  critical-service monitor, releases, public infrastructure/AI feeds, and
  selected bookmarks.
- The Home AdGuard monitor checks the Traefik-routed `dns` URL instead of the
  direct container port, because AdGuard's internal web port can move after first
  setup while Traefik owns the stable browser route.
- Hosting: native service monitors for core infrastructure and automation
  dependencies, specialist investigation links, and public releases for installed
  hosting components. It intentionally does not show host metrics, backup state,
  Healthchecks details, certificates, or container lists until those sources are
  separately approved.
- Technology: public videos, software releases, self-hosting/security feeds, and
  watch/read bookmarks.

Private Google Calendar events, WAN details, device names, media activity, and
Steam data are intentionally absent until their individual widget tasks approve
credentials and failure behavior.

Beszel-managed external hosts are the selected first external Hosting family, but
they are not rendered yet. Public source review found authenticated Beszel
PocketBase collections and a readonly role, but no stable OpenAPI/versioned API
contract. Task 70 must still verify the live Pi credential model, host aliases,
system IDs, allowed fields, stale behavior, and failure behavior before task 54
adds any Glance widget for those hosts.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
