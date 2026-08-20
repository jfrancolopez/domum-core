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

`glance.yaml` owns the global server, branding, theme, assets path, and page
order. Individual pages live under `pages/` and are included with Glance `v0.8.5`
`$include` syntax. Shared visual assets live under
`compose/monitoring/glance/assets/`; `domum.css` is loaded through Glance's
`custom-css-file` hook and the Domum-Core SVG mark replaces the old `DC` text
logo. Validate the complete include tree with:

```bash
tests/glance-config-validate.sh
```

Keep secrets out of this file. If a future widget needs a token, store the token
under `/etc/domum-core/secrets` and pass it through a file-backed environment
variable instead of committing it.

The optional direct-widget env file is:

```text
/etc/domum-core/secrets/glance.env
```

Use `config/glance.env.example` as the format. The Network page reads
`GLANCE_SPEEDTEST_TRACKER_TOKEN` from this file; use a Speedtest Tracker token
with only `results:read` scope. Do not reuse or mount Homepage's env file for
Glance.

The same file may contain `GLANCE_ADGUARD_USERNAME` and
`GLANCE_ADGUARD_PASSWORD` for the Network page's native `dns-stats` widget. Use a
Glance-specific AdGuard web account if practical; otherwise this is an
operator-approved AdGuard credential for aggregate stats only. The widget hides
top domains and does not render raw DNS queries, clients, or domain lists.

The same file also reserves UniFi variables for task 73:

```text
GLANCE_UNIFI_URL=
GLANCE_UNIFI_API_KEY=
GLANCE_UNIFI_API_HEADER=X-API-Key
GLANCE_UNIFI_API_PATH=
```

Use `GLANCE_UNIFI_URL` for the UCG Fiber gateway/controller URL reachable from
Glance, and `GLANCE_UNIFI_API_KEY` for a dedicated read-only key used only for
monitoring. Leave `GLANCE_UNIFI_API_PATH` blank until the live controller's safe
aggregate endpoint is verified. The future widget must not call endpoints that
return clients, topology, SSIDs, MAC addresses, IP addresses, or raw device
details.

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
- Network: branded command-page treatment with Speedtest Tracker's latest result
  rendered as human-readable WAN pulse metrics, aggregate AdGuard DNS stats with
  top domains hidden, plus compact reachability checks for approved
  network-adjacent services. It intentionally omits WAN IP, gateway topology,
  raw DNS activity, UniFi data, Tailscale device names, and internal addresses.
- Technology: public videos, software releases, self-hosting/security feeds, and
  watch/read bookmarks.

Private Google Calendar events, WAN identity details, device names, media activity, and
Steam data are intentionally absent until their individual widget tasks approve
credentials and failure behavior.

Beszel-managed external hosts are the selected first external Hosting family, but
they are not rendered yet. Public source review found authenticated Beszel
PocketBase collections and a readonly role, but no stable OpenAPI/versioned API
contract. Task 70 must still verify the live Pi credential model, host aliases,
system IDs, allowed fields, stale behavior, and failure behavior before task 54
adds any Glance widget for those hosts.

A Pi test later proved the configured Beszel username/password and two system IDs
are valid, but Glance `v0.8.5` still cannot render them natively: `custom-api`
cannot chain a login response token into a second collection request, and Beszel's
universal token did not authorize the systems collection API.

The normal PocketBase auth token can query the systems collection but expires
after 7 days, so it is not accepted as a static Glance credential.

The approved bridge direction is a small local read-only adapter, tracked as the
next implementation task. The adapter uses the existing `glance-beszel.env`
credential server-side, fetches only the two approved systems, strips fields that
reveal topology or identifiers, and exposes one internal JSON endpoint for a
later Glance `custom-api` widget. Do not add Beszel host widgets until that
adapter is Pi-validated, failure-tested, and documented as `Ready` in the
capability matrix.

The adapter service is disabled by default through:

```text
ENABLE_GLANCE_BESZEL_ADAPTER=0
```

Enable it only with both `ENABLE_GLANCE=1` and `ENABLE_BESZEL=1`;
`domum-core configure --validate` and `apply` reject the adapter without those
dependencies. It has no Traefik router and is intended only for the Docker
network path between Glance and Beszel. Its implementation is a repo-local static
Go binary built from `compose/monitoring/glance-beszel-adapter/`; no Go toolchain
is required on the Pi outside Docker build. It exposes `/summary` for Glance and
`/healthz` for direct internal checks.

### Beszel Adapter Pi Validation

Run these only on the production Pi after pulling the adapter commit. Do not
print `glance-beszel.env`, tokens, raw system IDs, raw JSON payloads, internal
addresses, container names, or disk identifiers.

1. Confirm the existing secret file exists and is root-only without showing
   values:

   ```bash
   sudo test -s /etc/domum-core/secrets/glance-beszel.env
   sudo stat -c '%U:%G %a %n' /etc/domum-core/secrets/glance-beszel.env
   ```

2. Enable only after Glance and Beszel are enabled:

   ```text
   ENABLE_GLANCE=1
   ENABLE_BESZEL=1
   ENABLE_GLANCE_BESZEL_ADAPTER=1
   ```

3. Validate config and deploy through the normal production path:

   ```bash
   sudo domum-core configure --validate
   sudo domum-core apply
   ```

4. Confirm the adapter is running without printing sensitive payloads:

   ```bash
   sudo docker inspect --format '{{.State.Health.Status}}' glance-beszel-adapter
   sudo docker run --rm --network domum-proxy curlimages/curl:latest \
     -fsS http://glance-beszel-adapter:8080/healthz
   ```

5. Check `/summary` shape from the same Docker network path. Save output to a
   root-only temp file, inspect keys/counts only, then delete it:

   ```bash
   tmp="$(sudo mktemp)"
   sudo docker run --rm --network domum-proxy curlimages/curl:latest \
     -fsS http://glance-beszel-adapter:8080/summary | sudo tee "$tmp" >/dev/null
   sudo python3 - <<'PY' "$tmp"
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
print("status", data.get("status"))
print("cache", data.get("cache"))
print("systems", len(data.get("systems", [])))
for item in data.get("systems", []):
    print("system", item.get("label"), item.get("status"), "stale", item.get("stale"))
PY
   sudo rm -f "$tmp"
   ```

6. Validate failure behavior during a maintenance window by testing invalid
   credentials, a missing configured system ID, Beszel unavailable, malformed or
   empty upstream behavior where practical, and stale cache behavior. Use a
   temporary env file or temporary service override; restore the real
   `/etc/domum-core/secrets/glance-beszel.env` before leaving the host.

7. If success and failure behavior match the task 72 contract, update the
   capability matrix in Git to move Host summary to `Ready`. Only then start task
   54 to render the Hosting widget.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
