# Task 77 — Add Steam and Twitch sources to Glance Games

## Objective

Build the Games page with popular Steam and Twitch signals while keeping profile,
friends, wishlist, and credential data bounded and explicitly approved.

## Background

Games is still the remaining placeholder page. Task 59 describes an ambitious
Steam/Twitch implementation, but the safe next step is to separate public store
signals from private account/profile signals and implement them in that order.

## Current Behavior

- Games has public gaming videos, gaming/PC/indie RSS feeds, a US-region Steam
  Specials widget using the public `featuredcategories` endpoint, and direct
  store/community links.
- `config/glance.env.example` reserves Steam and Twitch variables, but no widget
  consumes them yet.

## Desired Behavior

Games should show a useful dashboard such as Steam specials/top sellers, selected
gaming news, selected Twitch categories/creators, and optionally the operator's
recently played games if profile visibility and field policy are approved. Full
friends lists and raw profile data must not render.

## Implementation Plan

1. Public, no-credential gaming discovery is done. Keep it as the fallback mode
   for users without account integrations.
2. Done: Steam Store `featuredcategories?cc=us` provides public Specials data
   without an API key; the page renders bounded title, price, discount, and
   store-link fields only.
3. Generate a Steam Web API key and record only in
   `/etc/domum-core/secrets/glance.env` if private profile widgets are approved.
4. Register a Twitch developer app and use app client credentials only for public
   creator/category summaries.
5. Freeze allowed fields in `docs/glance-capability-matrix.md`.
6. Implement widgets with bounded item counts, cache limits, and safe failure
   states.

## Affected Files

- `compose/monitoring/glance/pages/games.yml`
- possible adapter for Steam/Twitch token exchange or response shaping
- `config/glance.env.example`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

## Testing Plan

- Run shell/YAML/Glance validation and Compose rendering.
- Test public-only mode, invalid Steam key, private Steam profile, empty recent
  games, invalid Twitch credentials, and rate limits.
- Confirm no API keys, friend identifiers, wishlist details, or unapproved profile
  data appear in HTML/logs/screenshots.

## Rollback

Revert the Games commit and deploy normally. Revoke Steam/Twitch credentials only
if they were exposed or the operator chooses to rotate them.

## Dependencies

- Operator approval for SteamID/profile visibility and allowed personal fields.
- Twitch developer app client credentials if Twitch widgets are implemented.
- Completion or supersession of task 59's plan.

## Risks

Steam data can expose identity, play habits, friends, and wishlists. Twitch API
tokens are less personal but still credentials. Keep account data opt-in.

## Complexity

Medium.

## Suggested Order

Start with public gaming news/store widgets, then add Steam profile, then Twitch.

## Decisions and Rejected Alternatives

- Decision: split public gaming discovery from private Steam account data.
- Decision: public Steam Specials is implemented without credentials; private
  profile, wishlist, friends, and play-history widgets remain opt-in.
- Decision: no full friends list by default.
- Rejected: using personal OAuth tokens for Twitch public summaries.
- Rejected: implementing all of task 59 in one large change.
