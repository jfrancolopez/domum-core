# Task 60 — Build the Glance News page

## Objective

Build a broad but finite daily briefing from high-quality RSS or documented
public feeds. Group sources by approved categories, favor original reporting,
cache aggressively, and prevent News from becoming an infinite noisy feed.

## Background

The operator selected a broad daily briefing. Candidate categories are
technology, cybersecurity, Linux, Docker, Kubernetes, AI, Home Assistant,
self-hosting, local, US, international, finance, gaming, and sports. Exact
priorities, sources, exclusions, Reddit usage, and thumbnail policy come from
task 47 and the capability matrix. Existing Glance already follows Home
Assistant, Kubernetes, Docker, Ars Technica, selfh.st, CNCF, and
BleepingComputer; these are candidates, not automatic approvals.

News and Social remain separate pages initially. Reddit/community discussion
normally belongs on Social; News should emphasize reporting and official project
feeds. Glance data is fetched on page load and cached, not continuously streamed.

## Current Behavior

The two current pages contain two mixed RSS widgets with 27 possible items and
one video widget. There is no category hierarchy, source rationale, duplicate
policy, freshness indicator, or measured thumbnail budget.

## Desired Behavior

News supports a useful morning/evening scan across approved categories, shows
source and age, limits repetition, and remains fast on the Pi and mobile. Empty
or failed feeds do not collapse the entire page. No paywall bypass, scraping, or
authenticated-news automation is introduced.

## Implementation Plan

1. Finalize category priority, preferred/disliked sources, local-news region,
   sports interests, finance scope, and thumbnail limits. Unresolved categories
   remain absent.
2. Prefer official project/security advisories and original publisher RSS/Atom.
   Reject scraped feeds, mutable third-party transformations, and sources whose
   terms or reliability are unclear.
3. Build category groups with explicit per-feed and per-widget limits. Keep the
   first viewport high-signal; collapse longer lists.
4. Avoid duplicate stories where native grouping/limits can reasonably do so.
   Do not build a custom deduplication service or claim semantic deduplication.
5. Use thumbnails only for categories where they improve recognition. Cap image
   count/size and test missing, slow, or tracking-heavy images. Prefer text for
   security/project feeds.
6. Use multi-hour caches, normally six hours, with justified exceptions for
   time-sensitive official alerts. Do not refresh every feed every minute.
7. Preserve only useful existing feeds; moving or deleting existing Glance feed
   widgets is in scope, but Homepage feeds/config are not.
8. Test malformed feed, duplicate entries, stale feed, unreachable source,
   Unicode/HTML title, huge image, and empty category behavior.
9. Update capability matrix with source URLs, rationale, cache, item/image caps,
   failure behavior, and tested status.
10. Obtain operator approval before Social.

## Affected Files

- `compose/monitoring/glance/pages/news.yml`
- approved feed includes under `compose/monitoring/glance/widgets/feeds/`
- approved local CSS/assets only
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `backlog/README.md` (status only)

Do not modify Homepage, FreshRSS, source websites, DNS, proxy, authentication,
or add a feed-processing service.

## Testing Plan

- Run repository, Compose, Glance, YAML, and gitleaks checks.
- Load every feed from the Pi and record success without committing article
  payloads or personal reading history.
- Test documented failure/empty/image cases and source links.
- Verify no category exceeds approved item/image/request budgets.
- Test all target widths and inspect cumulative image/network cost.
- Measure load time and Glance CPU/RAM versus Games.

## Rollback

Revert the News commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting update candidates. Prior feed config remains
in Git history; no external source or data needs rollback.

## Dependencies

Requires approved task 59 and resolved source/category decisions. Authenticated
feeds or feed adapters require a separate approved task.

## Risks

Too many feeds create noise, DNS/API load, and mobile bandwidth use. External
images can track clients. Strong limits and long caches are product requirements,
not optional optimization.

## Complexity

Medium curation/design work; low operational risk.

## Suggested Order

Phase 6 before Social so reporting and community content remain distinct.
