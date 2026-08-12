# Task 62 — Unify Glance visual and responsive design

## Objective

Turn the seven approved pages into one distinctive information-terminal visual
system, balancing dense NOC clarity with media-rich subtle cyberpunk styling and
Dracula/Domum continuity. Change presentation only; add no data sources/widgets.

## Background

The operator asked to compare dense NOC and media-rich cyberpunk directions and
wants a WOW factor across desktop and mobile. Page-by-page work can drift in
spacing, density, hierarchy, colors, images, and navigation. Reliability and
readability matter more than decorative novelty.

## Current Behavior

Tasks 51-61 should leave seven individually approved pages using real data. Task
51 selected an initial visual direction, but whole-dashboard consistency and all
target widths require a dedicated design pass.

## Desired Behavior

Home is calm, Hosting/Network are dense and analytical, Media/Games are visually
rich, and News/Social remain readable. Typography, spacing, focus, status colors,
images, empty/error states, and mobile order feel related without every page
looking identical.

## Implementation Plan

1. Capture sanitized current screenshots at every required width and identify
   hierarchy/density/overflow inconsistencies.
2. Define a small local design token system using Glance/theme/CSS capabilities
   actually supported by the pinned version. Do not add a framework, remote font,
   large library, or custom JavaScript chart package.
3. Normalize typography, spacing, cards, lists, bars, images, navigation, focus,
   hover, and compact failure/unknown states.
4. Use green/cyan/amber/red/gray/purple only for real semantic states; unknown
   and stale must never look healthy.
5. Tune page-specific density and responsive order from 390 px through 1920 px.
   Avoid horizontal scrolling, tiny tap targets, and image-heavy first paint.
6. Verify contrast, keyboard navigation, reduced-motion behavior where relevant,
   direct Glance, and existing Homepage embed without editing Homepage.
7. Remove decorative elements that add bandwidth or obscure information.
8. Obtain operator approval of final screenshots before hardening.

## Affected Files

- presentation-only files under `compose/monitoring/glance/assets/`
- page YAML only for layout/order/style properties, not data sources
- `docs/glance-dashboard-architecture.md`
- `docs/services/glance.md`
- `backlog/README.md` (status only)

Do not modify API URLs, credentials, source services, Homepage, proxy, or auth.

## Testing Plan

- Run repository, Compose, full Glance, YAML, and secret validation.
- Test 1920, 1440, 1024, 768, 430, and 390 px direct and embedded.
- Check keyboard/focus, contrast, overflow, long text, missing images, empty and
  error states.
- Compare transferred bytes and render/load behavior before/after.
- Obtain operator screenshot approval.

## Rollback

Revert the visual commit, update the checkout, then run a supervised full-stack
apply and checkup after inspecting update candidates. Data integrations remain.

## Dependencies

Requires approved tasks 50-61 and no unresolved broken widget dominating a page.

## Risks

CSS can break mobile/embedded layouts globally. Keep selectors narrow, test all
pages, and prefer removing decoration over adding complexity.

## Complexity

Medium design and responsive validation; low operational risk.

## Suggested Order

Phase 6 after all page content and before hardening.
