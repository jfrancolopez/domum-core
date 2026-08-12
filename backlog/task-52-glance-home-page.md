# Task 52 — Build the Glance Home page

## Objective

Deliver the first useful daily page: calm, information-dense context for the
current day without duplicating Homepage. Implement only capability-matrix rows
approved for Home and test every widget against real data.

## Background

The operator wants Durham-primary weather, secondary location context, a full
private calendar, date/time progress, search, important bookmarks, selected
alerts, and concise operational summaries. Homepage already owns the service
directory and fast status cards. Task 51 supplies modular config, chosen visual
foundation, validation, and safe credential plumbing. Task 48 defines privacy
and cache budgets.

## Current Behavior

The current Domum page has search, one bookmark group, five service monitors,
and an infrastructure/AI RSS list. It lacks calendar, weather, air quality,
time progress, event context, deliberate responsive hierarchy, and verified
private-data controls.

## Desired Behavior

Home answers: what time/context matters today, what is upcoming, whether a small
set of truly critical systems needs attention, and where to continue working.
It loads quickly on desktop and mobile. Missing APIs show compact useful fallback
states or omit the widget; no placeholder values appear.

## Implementation Plan

1. Re-read the approved Home rows in `docs/glance-capability-matrix.md`. Stop if
   location units, calendar scope, access proof, or private fields remain
   `Needs clarification`.
2. Design the mobile hierarchy first, then desktop columns. Keep no more than
   one primary weather treatment, one calendar/event treatment, one search, and
   one concise operational summary.
3. Use native date/calendar/weather/search/bookmark widgets where they meet the
   requirement. Use reviewed custom templates only for time progress, air
   quality, or summaries unsupported natively.
4. Implement Durham current conditions/forecast and only the approved compact
   secondary location clocks/weather. Respect chosen Fahrenheit/Celsius and
   `America/New_York` or the operator's updated timezone.
5. Add calendar only after LAN/Tailscale-only access is proven and its private
   feed is passed from `/etc/domum-core/secrets`. Limit event count and prevent
   private URLs from appearing in logs, links, or screenshots.
6. Migrate useful existing search/bookmarks and remove launcher duplication.
   Bookmarks should represent daily actions, code/work/utilities, or contextual
   resources rather than a mirror of Homepage services.
7. Add a deliberately small critical-status/alert summary from already approved
   sources. Do not expose the Docker socket or call every service.
8. Set cache, timeout, list, and image limits where the pinned Glance widget
   supports them. Record fixed upstream behavior or widgets with no network
   request instead of inventing unsupported options.
9. Test source failure, malformed/empty data, private-event rendering, slow API,
   and image failure. Broken widgets must not dominate the page.
10. Update docs and obtain operator approval before Hosting work starts.

## Affected Files

- `compose/monitoring/glance/pages/home.yml` or the task-51 approved equivalent
- approved reusable Home widgets under `compose/monitoring/glance/widgets/`
- approved lightweight assets/CSS under `compose/monitoring/glance/assets/`
- `docs/glance-capability-matrix.md`
- `docs/services/glance.md`
- `docs/reference/secrets.md` only for newly used credential names
- `backlog/README.md` (status only)

Do not edit Homepage, source services, proxy/authentication, or unrelated pages.

## Testing Plan

- Run repository, Compose, Glance include/template, yamllint, and gitleaks checks.
- On the Pi, confirm each widget with real data and deliberate failure behavior.
- Verify calendar/private values do not appear in Git, logs, or sanitized
  screenshots.
- Test direct and embedded page at 1920, 1440, 1024, 768, 430, and 390 px with
  no horizontal overflow.
- Compare load time, request count/bytes, CPU, and RAM to task 51 baseline.
- Record untested claims as untested and obtain explicit approval.

## Rollback

Revert the Home commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting pending update candidates. The modular
foundation remains. Do not delete credentials; unused secret files are safe.

## Dependencies

Requires task 51. Calendar/private-personal widgets additionally require task
49's access acceptance to remain proven on the Pi.

## Risks

Home can become overloaded or duplicate Homepage. Privacy leakage through
calendar links and external images is the highest data risk. Favor omission and
compact context over filling every column.

## Complexity

Medium configuration/design work; low operational risk after privacy gate.

## Suggested Order

Phase 2. Do not begin Hosting until the operator uses and approves Home.
