# Task 59 — Build the Glance Games page (Revised Implementation Plan)

## Objective

Build a comprehensive Games page that integrates Steam profiles and provides gaming data visualization with all requested features.

## Background

The operator chose to build upon existing Steam basics from task 59, extending it to include more advanced gaming information while maintaining privacy standards.

## Current Behavior

There is no dedicated Games page in Glance. The current games.yml file only contains a monitoring widget for critical services.

## Desired Behavior

Implement a full-featured Games page with:
1. Steam profile integration 
2. Recently played games tracking
3. Hours played statistics
4. Online/offline friends status
5. Top sellers and game sales information  
6. Wishlist discounts and alerts
7. Gaming news feeds
8. Twitch top games monitoring

## Implementation Plan

### Phase 1: Core Infrastructure Setup (Steam Integration)
1. Create a new directory structure for Steam widgets:
   - `compose/monitoring/glance/widgets/games/`
2. Add Steam API credential management following secrets.md guidelines
3. Create `steam-api-key` secret file in `/etc/domum-core/secrets/`

### Phase 2: Widget Development

#### A. Top Sellers & Specials Widget (Required)
- File: `compose/monitoring/glance/widgets/games/top-sellers.yml`
- Type: "games/top-sellers"
- API: Steam Storefront API
- Features:
  - Region/currency support 
  - Bounded item count (20 items max)
  - Real discount values calculation
  - No fake wishlist matches

#### B. Recently Played Games Widget  
- File: `compose/monitoring/glance/widgets/games/recently-played.yml`
- Type: "games/recently-played"
- API: Steam Web API
- Features:
  - Profile visibility handling (private/public)
  - Game history with titles, icons, play times
  - Error handling for private profiles/api failures

#### C. Hours Played Statistics Widget
- File: `compose/monitoring/glance/widgets/games/hours-played.yml`
- Type: "games/hours-played"
- API: Steam Web API  
- Features:
  - Total play time by game
  - Play time distribution visualization
  - Profile data handling

#### D. Friends Status Widget (Optional)
- File: `compose/monitoring/glance/widgets/games/friends-status.yml`
- Type: "games/friends-status"
- API: Steam Web API
- Features:
  - Online/offline status indicators
  - Avatar display (if approved by privacy audit)

#### E. Wishlist Discounts Widget (Optional) 
- File: `compose/monitoring/glance/widgets/games/wishlist-discounts.yml`
- Type: "games/wishlist-discounts"
- API: Steam Web API or community endpoints
- Features:
  - Discount alerts for wishlist items
  - Price tracking with change detection

#### F. Gaming News Feed Widget (Optional)
- File: `compose/monitoring/glance/widgets/games/news-feed.yml`
- Type: "games/news-feed"
- API: RSS feeds from gaming news sources or Steam news
- Features:
  - Curated gaming news articles
  - Category filtering by game type

#### G. Twitch Top Games Widget (Optional)
- File: `compose/monitoring/glance/widgets/games/twitch-top.yml`
- Type: "games/twitch-top"
- API: Twitch Helix API
- Features:
  - Current top games on Twitch
  - Viewer counts and stream information

### Phase 3: Page Configuration Update 

1. Modify `compose/monitoring/glance/pages/games.yml` to include all widgets in a structured layout
2. Organize content into logical sections with proper column sizes
3. Set appropriate cache refresh intervals based on data volatility:
   - Top sellers/specials: 1h (less volatile)
   - Recently played: 5m (more frequent updates)
   - Hours played: 1h 
   - Friends status: 5m
   - Wishlist discounts: 30m
   - News feeds: 15m
   - Twitch top games: 10m

### Phase 4: Documentation Updates

1. Update `docs/glance-capability-matrix.md` to reflect new game widgets:
   - Add entries for each widget type with privacy status, resource usage, cache times 
2. Document Steam API setup process in `docs/services/glance.md`
3. Add secret management instructions for gaming credentials
4. Create a dedicated games configuration documentation file

## Affected Files

### New Files to be Created:
1. `compose/monitoring/glance/widgets/games/top-sellers.yml`
2. `compose/monitoring/glance/widgets/games/recently-played.yml` 
3. `compose/monitoring/glance/widgets/games/hours-played.yml`
4. `compose/monitoring/glance/widgets/games/friends-status.yml` (optional)
5. `compose/monitoring/glance/widgets/games/wishlist-discounts.yml` (optional)
6. `compose/monitoring/glance/widgets/games/news-feed.yml` (optional)
7. `compose/monitoring/glance/widgets/games/twitch-top.yml` (optional)
8. `docs/reference/gaming-secrets.md` - documentation for gaming-related secrets

### Modified Files:
1. `compose/monitoring/glance/pages/games.yml` 
2. `docs/glance-capability-matrix.md`
3. `docs/services/glance.md`

## Testing Plan

- Test public discovery without credentials and account widgets with the actual approved read-only setup
- Verify region/currency handling for different Steam regions  
- Test private profile, invalid/limited credential responses
- Validate empty history, API timeout, rate limiting scenarios 
- Confirm no ID, key, friend data enters Git/logs/screenshots
- Test image loading fallbacks and missing artwork handling

## Rollback

Revert the Games commit, update the checkout, then run a supervised full-stack apply and checkup after inspecting update candidates. Do not change Steam privacy settings or delete external secret files during rollback.

## Dependencies

Requires approved task 58 (Steam basics matrix) and resolved Steam API credentials handling. Other platforms like Twitch have no implied authorization.

## Risks

Account identifiers are personal; artwork is bandwidth-heavy; store endpoints may vary by region. Keep scope small and distinguish private, missing, and failed data clearly.

## Complexity  

Medium configuration and API review; low-medium privacy/resource risk.

## Suggested Order 

Phase 5: Steam basics first; optional gaming sources only after acceptance.