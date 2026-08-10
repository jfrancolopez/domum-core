# Task 67 — Build complete Glance Network page

## Objective

Build a comprehensive private Network dashboard that includes:
1. Public IP and ISP information 
2. WAN state monitoring
3. Gateway uptime tracking
4. Speedtest history and performance metrics (download/upload/ping/jitter)
5. UniFi client/AP/switch monitoring
6. AdGuard DNS stats and query history
7. Tailscale device status and connectivity
8. Network alerts and latency monitoring

## Background

This task builds upon the core network foundation established in tasks 55 and 56, expanding the Glance dashboard to provide comprehensive visibility into the home network's performance, devices, and security.

The operator has selected deep private network visibility with careful attention to privacy protection. All data sources must be read-only, properly scoped, and respect privacy boundaries.

## Current Behavior

The current Glance implementation only provides basic homepage metrics but lacks a dedicated Network page with detailed monitoring capabilities for the various network components.

## Desired Behavior

Create a unified Network dashboard that:
- Shows public IP address and ISP information
- Monitors WAN connection state and uptime 
- Displays speedtest history and performance metrics (download/upload/ping/jitter)
- Provides UniFi device health status
- Shows AdGuard DNS statistics and query history
- Monitors Tailscale device connectivity
- Implements network alerts for latency issues

## Implementation Plan

### 1. Create core Network page structure
- Create `compose/monitoring/glance/pages/network.yml`
- Define the layout with appropriate widget placements

### 2. Implement Public IP and ISP information  
- Add widget to fetch public IP via external API
- Display ISP information alongside IP address
- Include location information if available from source

### 3. Implement WAN state monitoring
- Monitor gateway connection status 
- Track WAN uptime metrics
- Show RX/TX traffic data
- Display current ISP details

### 4. Implement Speedtest history and performance
- Integrate with existing Speedtest Tracker API
- Display latest test results (download/upload/ping/jitter)
- Show historical speedtest trends
- Include timestamp information for each test

### 5. Implement UniFi monitoring  
- Create widget to access UniFi controller APIs
- Monitor client device health status
- Track AP and switch performance metrics
- Show connected devices count with read-only scope

### 6. Implement AdGuard DNS stats
- Integrate with AdGuard Home API for statistics
- Display query counts, blocked queries, and response times
- Show recent query history (without exposing sensitive data)
- Include DNS resolution performance metrics

### 7. Implement Tailscale device status monitoring
- Access Tailscale API for device information 
- Monitor online/offline status of devices
- Track update availability and connectivity
- Display device count with privacy protection

### 8. Implement network alerts and latency monitoring
- Create probe set for local service latency testing
- Establish baseline measurements for performance thresholds
- Implement alerting for sustained increases in latency
- Show outage history with appropriate privacy controls

## Affected Files

### Creation/Modification:
- `compose/monitoring/glance/pages/network.yml` - Main network dashboard layout
- `compose/monitoring/glance/widgets/network/public-ip.yml` - Public IP and ISP widget
- `compose/monitoring/glance/widgets/network/wan-status.yml` - WAN state monitoring widget  
- `compose/monitoring/glance/widgets/network/speedtest-history.yml` - Speedtest history widget
- `compose/monitoring/glance/widgets/network/unifi-monitor.yml` - UniFi device monitoring widget
- `compose/monitoring/glance/widgets/network/adguard-dns.yml` - AdGuard DNS stats widget
- `compose/monitoring/glance/widgets/network/tailscale-status.yml` - Tailscale device status widget
- `compose/monitoring/glance/widgets/network/alerts-latency.yml` - Alerts and latency monitoring widget

### Documentation Updates:
- `docs/glance-capability-matrix.md` - Add new network widgets to capability matrix
- `docs/services/glance.md` - Update Glance documentation with new capabilities

## Testing Plan

1. Run repository, Compose, Glance, YAML validation
2. Cross-check metrics and units against source applications at matching times
3. Verify all identifiers are properly classified and protected per privacy matrix  
4. Test API timeout, stale cache, partial history, empty device list, and rate limit behavior
5. Validate thresholds with sustained samples rather than single requests
6. Test all target widths and measure page/network/container resource cost
7. Confirm homepage is unchanged and existing Speedtest widget still works
8. Test outage scenarios for each data source

## Rollback

Revert the core Network commit, update the checkout, then run a supervised full-stack apply and checkup after inspecting update candidates. Credentials may remain unused; never delete or overwrite them during rollback.

## Dependencies

- Approved task 55 (core network page)
- Approved task 56 (network service families) 
- Proven private access boundary from task 49
- `Ready` core Network rows and source family approvals

## Risks

This dashboard has high privacy risk as it accesses sensitive household data through multiple APIs. Raw DNS/Tailscale/UniFi data could reveal family behavior and network topology. Must use summaries, caching, strict limits, read-only scopes, and explicit unknown states.

## Complexity

High configuration and integration work; high privacy/operational risk.

## Suggested Order

Phase 3 after core Network implementation (tasks 55-56) are complete.