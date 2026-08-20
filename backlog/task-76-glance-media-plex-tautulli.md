# Task 76 — Add Plex/Tautulli media intelligence to Glance Media

## Objective

Add a private media activity widget to the Media page using Tautulli or Plex only
after API scope, token handling, and privacy behavior are reviewed.

## Background

Media is currently public discovery only. A popular next step is "what is playing
now," recent library activity, or high-level watch trends. These signals are
useful but private because they reveal household viewing behavior.

## Current Behavior

- Media shows public videos, film/TV feeds, books/culture feeds, and links.
- `config/glance.env.example` reserves Tautulli and Plex variables, but no widget
  consumes them yet.

## Desired Behavior

Glance shows a bounded media summary such as active streams count, recently added
media count, or now-playing titles if explicitly approved. It should prefer
Tautulli because it is purpose-built for Plex summaries and avoids embedding Plex
tokens directly in templates.

## Implementation Plan

1. Verify whether Tautulli is installed/enabled and reachable from Glance.
2. Generate a Tautulli API key from Settings -> Web Interface/API and store it in
   `/etc/domum-core/secrets/glance.env`.
3. Review Tautulli endpoints and select allowed fields.
4. Decide whether titles/posters/usernames are allowed or whether the widget must
   stay aggregate-only.
5. Implement one Media widget with safe failures and no URL-embedded secrets.
6. Document token setup and field policy.

## Affected Files

- `compose/monitoring/glance/pages/media.yml`
- possible adapter if direct `custom-api` cannot hide tokens/shape data safely
- `config/glance.env.example`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md`
- `backlog/README.md`

## Testing Plan

- Run shell/YAML/Glance validation and Compose rendering.
- Test no active streams, active stream, unavailable Tautulli, invalid key, and
  slow API response.
- Inspect rendered HTML/logs for tokens, usernames, internal URLs, or unapproved
  titles/posters.

## Rollback

Revert the widget/adapter commit and deploy normally. Do not delete or rotate the
Tautulli key unless it was exposed.

## Dependencies

- Tautulli or Plex service availability.
- Operator decision on whether titles/posters/usernames may render.
- Private Glance access boundary must remain enforced before personal media data.

## Risks

Media history reveals personal behavior. Keep defaults aggregate and require
explicit approval for titles, posters, and usernames.

## Complexity

Medium.

## Suggested Order

Do this after public Media has been accepted and before adding more media apps.

## Decisions and Rejected Alternatives

- Decision: prefer Tautulli over direct Plex for dashboard summaries.
- Decision: aggregate-only is the safe default.
- Rejected: URL query-string API keys in committed templates.
- Rejected: showing every recent item by default.
