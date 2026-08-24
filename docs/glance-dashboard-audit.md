# Glance Dashboard Audit

## Scope and Status

This report was started from the repository checkout and continued on the
production Raspberry Pi on 2026-08-11. It is not a live-deployment acceptance
report: LAN, Tailscale, external-client, browser, and performance acceptance
remain incomplete.

No secrets, ignored runtime configuration, service `data/` directories,
addresses, account identifiers, private URLs, private payloads, or screenshots
were inspected for this report.

## Verified Repository Facts

- The Glance service is catalogued as an optional monitoring dashboard behind
  `ENABLE_GLANCE`.
- The tracked service definition is `compose/monitoring/glance.yml`.
- The tracked configuration directory is mounted read-only at `/app/config`.
- Glance has access only to the `domum-proxy` Docker network. It has no Docker
  socket or host-filesystem mount.
- The configured image is pinned through `GLANCE_IMAGE`, currently
  `glanceapp/glance:v0.8.5`.
- The running image identifier is
  `sha256:32ab73d80f2b8b5fb0735b0431deb36b93fbb6b2fb43592449b0178c8b83e350`.
- An external fetch identified the running application as Glance `v0.8.5`.
- The service definition has a Traefik router for `dash.${DOMUM_DOMAIN}`.
  The legacy hostname is no longer resolvable from the Pi.
- The repository labels alone cannot prove an access restriction or external
  reachability; the Pi audit below records the observed trusted and denied paths.
- Homepage embeds/links Glance and is approved. It is outside the dashboard
  program scope.
- The service inventory records Glance, Beszel, Healthchecks, Speedtest Tracker,
  AdGuard Home, Tailscale, Karakeep, and FreshRSS as known domum-core services.
  It does not establish the live availability or API capability of any other
  requested host or service.

## Pi Audit Findings

- The Pi hostname is `domum-core`.
- Glance is attached only to the `domum-proxy` network and has a read-only
  `/app/config` mount. Its visible environment variable names are `TZ`,
  `DOMUM_DOMAIN`, and `PATH`.
- Glance has no container health check.
- Before recovery, Glance was crash-looping because its configuration had no
  recognized `pages` section. The unsupported top-level `includes` structure
  was the immediate cause.
- The last known-good two-page configuration was restored from repository
  history, then only the Glance container was recreated. Glance is now running
  and reports that it started its server on port 8080.
- `dash.ladomum.com` returned HTTP 200 from the Pi after its Traefik router was
  updated, then returned HTTP 200 with a valid TLS certificate. The legacy
  hostname did not resolve from the Pi.
- An independent external fetch successfully rendered the dashboard. This
  proves that `dash` is publicly reachable and does not meet the operator's
  chosen LAN/Tailscale-only boundary at the time of the initial audit.
- Traefik successfully completed DNS certificate issuance for the new hostname.
- A single `docker stats` sample reported no measurable Glance CPU or memory
  use. This is insufficient for a performance baseline and must be repeated
  after browser-based page-load measurement.
- Task 49 attached a Glance-only Traefik IP allowlist after the operator approved
  local-only LAN CIDR configuration. The active rule has exactly two ranges: the
  private LAN CIDR and Tailscale CGNAT range. The CIDR value is intentionally
  omitted from this report.
- LAN and Tailscale-origin requests returned HTTP 200. An untrusted Docker
  network client returned HTTP 403. A forged `X-Forwarded-For` header did not
  affect the direct LAN request result; no forwarded-header trust was configured.
- A genuine external non-tailnet mobile-data test returned Forbidden, as
  expected.
- A Tailscale Mac client initially received Forbidden because Docker's userland
  proxy hid the real tailnet source from Traefik. Disabling Docker
  `userland-proxy`, restarting Docker, and re-applying the stack restored
  Tailscale client access. The Glance allowlist remained the private LAN CIDR
  plus Tailscale CGNAT range; no temporary host-specific `/32` allowlist was
  retained.
- Host-local curl tests from the Pi are not accepted as LAN/Tailscale evidence
  because they can traverse local Docker/NAT paths that do not match real client
  source addresses.

## Operator Decisions

- Glance is the private deep-information dashboard; Homepage remains the
  service launcher and fast operational overview.
- Desired access is LAN and Tailscale only. External non-tailnet access must be
  denied before private dashboard content is enabled.
- `dash.ladomum.com` is the desired Glance hostname. DNS was changed outside the
  repository; its resolution and routing behavior must be tested on the Pi.
- The old `glance.ladomum.com` route must remain until the new hostname is proven
  functional from LAN and Tailscale and denied from an external client. DNS for
  the legacy hostname has already been removed, so task 49 must instead confirm
  that no legacy Traefik route remains before documenting retirement.
- Current page order is Home, Hosting, Network, Media, Games, News, Social, then
  Technology. Home was the first page after the runtime and visual foundation.
- The visual foundation must compare dense-NOC and media-rich subtle-cyberpunk
  prototypes before the operator selects one.
- Dynacat is deferred until the Glance program is complete.
- Use Fahrenheit. Durham is the primary weather location; Laredo, Nuevo Laredo,
  and San Jose initially show clocks only.
- After task 75 receives its approved ICS, Home Assistant token, and person
  allowlist, show a bounded calendar and named presence summary on the private
  dashboard.
- WAN identity, internal aliases, device names, media activity, and Steam friends
  still require separate source and field-policy approval.
- The current Games scope is public Steam Specials, gaming videos, and selected
  gaming feeds. Do not render Steam profile, wishlist, play-history, friends, or
  Twitch data until task 77's inputs are approved.
- Plex is the primary Media integration. Verify any related media applications
  on the media host before selecting additional sources.
- News uses curated infrastructure, self-hosting, Home Assistant, security,
  Linux, project-release, and AI sources. Social uses Hacker News, Lobsters,
  selected public forums, videos, and direct links; Reddit remains deferred after
  rate-limit/forbidden source tests. Social remains curated rather than an
  unbounded feed.
- Use bounded thumbnails for Media, Games, and selected feeds. Text remains the
  default for dense operational and news content.

## Historical Audit-Time Worktree Risk

The following findings describe the checkout at the time of the initial audit on
2026-08-11, before the later foundation and page commits. They are retained as
historical context, not as a description of the current Git state.

The Glance-related worktree contains uncommitted implementation and
documentation changes that are outside the completed program sequence. They
must not be treated as deployed or validated functionality.

Observed issues include unverified/invented dashboard values, unsupported or
unproven widget configuration, incomplete page wiring, and claims of credentials
or APIs without runtime plumbing. The operator has chosen to revert only these
uncommitted implementation changes later. Preserve them unchanged during task
47; create an approved remediation task after this audit is accepted.

One prior committed Network implementation also requires a separate review. It
is not authorized for reversion by this audit and must not be deployed as proof
of a private Network dashboard.

## Subsequent Repository State

The later Glance implementation is now committed and pushed. The current tracked
configuration has a validated `v0.8.5` include tree with Home, Hosting, Network,
Media, Games, News, Social, and the retained Technology page. Current pages use
only native widgets or reviewed local `custom-api` templates; private account
integrations remain absent unless their matrix row is explicitly approved.

The Beszel adapter, Speedtest Tracker summary, aggregate AdGuard stats, and
aggregate UniFi health path are implemented. The operator has confirmed the
Beszel production data path. Pi-only responsive screenshots, request/byte counts,
and resource measurements remain acceptance work and are not inferred from this
checkout.

The public-safe dashboard additions include Steam Specials, native Hacker
News/Lobsters widgets, bounded public repository activity, curated media/news/
social feeds, and keyboard/reduced-motion accessibility behavior. No credentials,
private payloads, client identities, raw DNS activity, topology, or account
history are tracked.

## Pi-Only Evidence Required

Complete these read-only checks on the production Pi before marking task 47 done:

1. Record Glance container/image version, digest, state, mounts, networks, and
   environment-variable names only.
2. Determine version-matched configuration and reload behavior from upstream
   documentation and the installed binary or image metadata.
3. Capture sanitized responsive findings at the six task-47 target widths.
4. Measure Glance idle/load CPU and RAM plus one page-load request and byte
   baseline.
5. Inventory approved host aliases, service/API presence, and available
   read-only authentication mechanisms without reading credential values.

## Open Operator Inputs

The following decisions are still needed for task 48's capability matrix:

- Calendar groups beyond the initial seven upcoming titled events.
- Exact Steam profile visibility and the friends allowlist.
- Which media applications actually exist alongside Plex.
- Exact sources, exclusions, Reddit communities, and creator/repository feeds.
- Hosting and Network source priorities after core data-source availability is
  verified.

## Next Step

Obtain the Pi-only audit evidence and operator input, then have the operator
approve this report. Only then may task 48 define the architecture and
capability matrix. No dashboard, access-control, secret-plumbing, or routing
change is authorized by this report.
