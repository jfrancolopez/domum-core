# Task 78 — Add Spotify and YouTube learning recommendations to Glance

## Objective

Add a personal learning/recommendation page or widget that uses Spotify listening
signals and YouTube follow/watch signals to suggest what to listen to, watch, or
follow next, without leaking private history or granting write access.

## Background

The operator wants Glance to learn from recent Spotify listening and YouTube
subscriptions/activity, then recommend useful next items or creators to follow.
This is a popular dashboard pattern because it turns passive history into a daily
discovery surface. It is also highly private because listening and watch patterns
reveal taste, routine, mood, politics, religion, health, and family context.

## Why This Exists

Spotify and YouTube require OAuth and can expose broad account data. A future
implementation needs a deliberate boundary: read-only scopes, local-only scoring,
explainable recommendations, and no automatic account actions.

## Current Behavior

- Social uses only public creator videos, public HN/Lobsters feeds, and selected
  public forum RSS feeds. Reddit RSS is not rendered because its public endpoint
  returned rate-limit/forbidden responses during source smoke testing.
- Media uses only public discovery feeds and links.
- `config/glance.env.example` reserves Spotify and YouTube variables, but no
  widget consumes them yet.
- There is no recommendation engine or account-backed music/video integration.

## Desired Behavior

Glance shows a small daily recommendation surface such as:

- recent Spotify listening themes;
- top artists/genres over a bounded window;
- followed YouTube channels with recent uploads;
- "try next" artists, albums, channels, or videos;
- an explanation for each recommendation, such as "because you listened to X" or
  "because this channel overlaps with Y."

The widget must be read-only. It must not create playlists, follow artists,
subscribe to channels, like videos, post comments, or write back to either
account.

## Implementation Plan

1. Decide where the feature belongs: a new Music/Learning page, the Social page,
   or a Home sidebar card. Prefer a separate page if history/details are shown.
2. Define approved Spotify OAuth scopes. Candidate scopes are
   `user-read-recently-played`, `user-top-read`, `playlist-read-private`, and
   `user-follow-read`; approve the smallest set that supports the design.
3. Define approved YouTube access. Prefer public channel/subscription metadata
   first. Review whether watch history is available through the YouTube Data API,
   Google Takeout, browser export, or not at all; do not assume it is available.
4. Implement OAuth token acquisition/refresh outside committed config. Store any
   refresh token only in `/etc/domum-core/secrets/glance.env` or a dedicated
   root-only secret file.
5. Decide whether direct Glance `custom-api` is sufficient. If token refresh,
   merging, caching, or recommendation scoring is needed, implement a small local
   read-only adapter instead of embedding OAuth logic in YAML.
6. Build a simple local recommendation algorithm first: recency, frequency,
   followed-channel overlap, genre/artist/channel similarity, and explicit source
   explanations. Do not call an external LLM with raw listening/watch history
   unless a later task approves that data flow.
7. Freeze allowed fields in `docs/glance-capability-matrix.md` before rendering:
   item title, creator/artist, source service, thumbnail policy, reason text,
   and age/window.
8. Add safe failure states for expired tokens, revoked consent, quota limits,
   private/empty history, and unavailable APIs.

## Affected Files

- `compose/monitoring/glance/pages/social.yml` or a new approved page under
  `compose/monitoring/glance/pages/`
- possible local adapter under `compose/monitoring/` if OAuth refresh/scoring is
  required
- `config/glance.env.example`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

## Testing Plan

- Run shell/YAML/Glance validation and Compose rendering.
- Test expired refresh token, revoked consent, API quota/rate limits, no recent
  listening, private playlists, no subscriptions, unavailable API, and empty
  recommendation set.
- Inspect rendered HTML, logs, screenshots, and adapter responses for access
  tokens, refresh tokens, raw history dumps, private playlist names, and
  unapproved watch/listen details.
- Confirm the widget remains useful with only public YouTube channel metadata if
  personal watch history is rejected.

## Rollback

Revert the widget/adapter commit and deploy normally. Revoke Spotify/Google OAuth
clients or refresh tokens only if they were exposed, over-scoped, or the operator
chooses to disable the feature.

## Dependencies

- Operator approval for Spotify scopes.
- Operator approval for YouTube source and scopes.
- Private Glance access boundary must remain enforced.
- A decision on whether recommendations stay local-only or may use an external
  model/service.

## Risks

Listening and watch history are private-personal and can reveal sensitive
interests. OAuth refresh tokens are powerful long-lived secrets. Recommendation
systems can also feel invasive if they show too much raw history. Keep output
bounded, explainable, read-only, and locally scored by default.

## Complexity

Medium-large if a local adapter handles OAuth refresh and scoring; medium if the
first version uses public YouTube feeds plus Spotify top/recent endpoints only.

## Suggested Order

1. Implement Spotify recent/top summaries first.
2. Add YouTube subscriptions/recent uploads using the least private source.
3. Add explainable local recommendations.
4. Consider richer recommendation sources only after the first version is useful.

## Decisions and Rejected Alternatives

- Decision: this feature is read-only and must not write to Spotify or YouTube.
- Decision: local explainable scoring is the default recommendation approach.
- Decision: raw account history must not be sent to an external LLM/service by
  default.
- Rejected: using a personal Google account token with broad scopes before source
  review.
- Rejected: auto-following channels/artists or auto-creating playlists.
- Rejected: rendering full watch/listen history by default.
