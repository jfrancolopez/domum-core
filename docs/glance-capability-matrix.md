# Glance Capability Matrix

| Widget | Page | Data source | Native/custom | Credential | Refresh/cache | Privacy | Resource | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Infrastructure Overview | Hosting | Beszel, Host APIs | Native | None | 5m | Public | Low | Ready | Shows host status and basic info |
| System Metrics Table | Hosting | Beszel | Native | None | 5m | Public | Low | Ready | CPU, RAM, temp, disk usage, load average, uptime |
| Docker Container Status | Hosting | Beszel | Native | None | 5m | Public | Low | Ready | Container running status and health |
| Backup Status Table | Hosting | Restic API/Files | Native | None | 15m | Public | Low | Ready | Shows backup target statuses |
| Security Updates Table | Hosting | System package manager | Native | None | 1h | Public | Low | Ready | Lists available updates with reboot requirement |
| Service Monitor | Hosting | HTTP checks | Native | None | 1m | Public | Low | Ready | Monitors critical service URLs |
| Healthcheck Status | Hosting | Healthchecks API | Native | None | 5m | Public | Low | Ready | Shows healthcheck execution status |
| Beszel Metrics Summary | Hosting | Beszel APIs | Native | None | 5m | Public | Low | Ready | Summary of key metrics from Beszel |
| Public IP and ISP Info | Network | External API | Custom | None | 1h | Public | Low | Planned | Shows public IP address and ISP information |
| WAN State Monitoring | Network | Gateway APIs | Native | None | 1m | Public | Low | Planned | Monitors gateway connection status and uptime |
| Gateway Uptime Tracking | Network | Gateway APIs | Native | None | 5m | Public | Low | Planned | Tracks gateway uptime metrics |
| Speedtest History | Network | Speedtest Tracker API | Native | None | 5m | Public | Low | Planned | Displays speedtest history with performance metrics |
| UniFi Client/AP/switch Status | Network | UniFi Controller APIs | Custom | Read-only | 5m | Private | Medium | Planned | Shows device health and counts for clients, APs, switches |
| AdGuard DNS Stats | Network | AdGuard Home API | Custom | Read-only | 1m | Private | Low | Planned | Displays DNS statistics and query history |
| Tailscale Device Status | Network | Tailscale API | Custom | Read-only | 5m | Private | Low | Planned | Monitors device connectivity and status |
| Network Alerts/Latency | Network | Internal probes | Native | None | 1m | Public | Low | Planned | Shows network alerts and latency monitoring |

## Notes

- All widgets use read-only, non-invasive data sources
- No credentials or secrets are exposed in the dashboard  
- Data is cached according to default cache budget guidelines
- All widgets are designed for minimal resource usage on Raspberry Pi
- Privacy status indicates whether widget displays potentially sensitive information