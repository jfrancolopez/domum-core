# Task 61 — Build the Glance Social page

## Objective

Build a curated public-community page using approved Reddit, YouTube, Twitch,
GitHub, Hacker News, Lobsters, Mastodon, Bluesky, and RSS sources. Use public or
documented unauthenticated APIs only in the first release.

## Background

The operator selected public curated feeds and has not approved authenticated
account scraping. Exact creators, repositories, communities, topics, and image
preferences come from task 47. Existing Glance has YouTube channels, Hacker News
as a bookmark, and no dedicated community hierarchy. News remains a separate
publisher/official-feed page.

## Current Behavior

Social/video/community items are mixed into Technology and bookmark widgets.
There is no explicit curation limit, public-source policy, or boundary between
creator updates and news reporting.

## Desired Behavior

Social surfaces a small set of communities and creators worth checking without
becoming an infinite feed. It links out for interaction, performs no posting or
account action, and exposes no authenticated timeline, saved item, notification,
or private subscription unless a later task is explicitly approved.

## Implementation Plan

1. Finalize approved public channels, Twitch names, GitHub repositories/topics,
   subreddits, Mastodon instances, Bluesky feeds, and Hacker News/Lobsters use.
2. Use native Glance widgets where possible. Verify each source's current public
   API/feed behavior and limits against the pinned Glance version.
3. Organize by intent: creators/video, code/projects, technical communities, and
   discussion. Avoid repeating News headlines or Games discovery widgets.
4. Apply strict source/item/image limits and one-hour or longer caches unless a
   documented source requires otherwise. Live Twitch status may use a shorter
   approved cache, but not sub-minute polling.
5. Show thumbnails only where they aid recognition. Avoid autoplay, embedded
   trackers, and large iframe players in the initial page.
6. Use GitHub releases/activity that provides new context, not a copy of the
   Hosting release list. Private GitHub notifications and authenticated account
   data remain out of scope.
7. Review Reddit/Mastodon/Bluesky title and HTML rendering for injection and
   offensive/NSFW content controls available from the source/widget. Document
   limitations rather than claiming perfect filtering.
8. Test deleted/private community, unavailable channel, API limit, empty feed,
   malformed title, missing thumbnail, and source outage behavior.
9. Update matrix with actual source, cache, privacy/resource classification, and
   tested status.
10. Obtain operator approval before whole-dashboard polish.

## Affected Files

- `compose/monitoring/glance/pages/social.yml`
- approved Social includes under `compose/monitoring/glance/widgets/feeds/` or
  a task-51 established equivalent
- approved local CSS/assets only
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `backlog/README.md` (status only)

Do not modify Homepage, social accounts, source services, authentication, or add
scraping/bridge services.

## Testing Plan

- Run repository, Compose, Glance, YAML, and secret checks.
- Verify every source is public and does not receive a committed credential.
- Test source failure, empty/private/deleted feeds, rate limits, escaping, and
  missing images.
- Confirm links open the intended canonical source and no action controls exist.
- Test all target widths and enforce item/image/request budgets.
- Measure page and Glance resource cost versus News.

## Rollback

Revert the Social commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting update candidates. No external account or
source state is changed.

## Dependencies

Requires approved task 60 and a finalized public-source list. Authenticated APIs,
RSS bridges, or adapters need separate approval and tasks.

## Risks

Public feeds can contain unsafe text/images, change APIs, or consume excessive
bandwidth. Curate tightly, escape content, document moderation limitations, and
fail compactly.

## Complexity

Medium curation/configuration work; low operational risk.

## Suggested Order

Phase 6 after News.
