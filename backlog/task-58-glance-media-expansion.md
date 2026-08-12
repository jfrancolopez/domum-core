# Task 58 — Add one Media integration family

## Objective

After core playback/library approval, add exactly one highest-value Media family
marked `Ready`: Immich, audio/music, download queue, media storage/host, request
management, or trending/discovery. Do not combine unrelated APIs.

## Background

Task 56 deliberately limits Media to one playback and one library/release source.
Possible follow-ons have different privacy, image, credential, and performance
profiles. The operator selected inventory-before-design, so absent/deferred
services must not generate cards.

## Current Behavior

Use task 57 and the matrix as facts. Extension containers, adapters, playback
controls, source-service changes, and unapproved external API keys remain out of
scope.

## Desired Behavior

One coherent Media section adds clear value, bounded imagery/items, compact
failure behavior, and a specialist-UI link without making the page noisy or
slower than its approved budget.

## Implementation Plan

1. Select one `Ready` family with the operator and freeze fields/privacy limits.
2. Verify official API/version and minimum read-only credential scope.
3. Audit any community template fully at an immutable commit, including HTML
   escaping, image origins, requests, pagination, cache, rate limits, and license.
4. Implement only real approved values. No playback controls, fake queues,
   synthetic storage history, or unsupported charts.
5. Bound posters/thumbnails and list size; label source age and partial data.
6. Test empty, unauthorized, malformed, slow, stale, missing-image, and unusual
   title/user content.
7. Update matrix/docs and write separate tasks for other now-Ready families.
8. Obtain operator approval before Games.

## Affected Files

- `compose/monitoring/glance/pages/media.yml`
- one family directory under `compose/monitoring/glance/widgets/media/`
- approved local CSS/assets only
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` for names/scopes only
- `backlog/README.md` and justified follow-up task files

Do not modify media applications, databases, storage, download clients, Homepage,
networking, or authentication.

## Testing Plan

- Run repository, Compose, Glance, YAML, and secret validation.
- Cross-check real values and every failure/escaping case.
- Verify titles/users/images follow the privacy matrix.
- Test all target widths and measure incremental bytes/requests/CPU/RAM.
- Confirm the diff contains one integration family only.

## Rollback

Revert the family commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting update candidates. Do not delete credentials.

## Dependencies

Requires approved task 57 and one fully `Ready` expansion family.

## Risks

Personal activity and external artwork can leak interests and consume bandwidth.
One-family scope, escaping, image limits, and read-only credentials are mandatory.

## Complexity

Medium for one source family; medium privacy/resource risk.

## Suggested Order

Phase 4 after core Media. Additional families become separate tasks.
