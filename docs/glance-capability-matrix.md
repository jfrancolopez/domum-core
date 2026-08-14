# Glance Capability Matrix

This matrix is the authorization boundary for the dashboard program. It was
checked against Glance `v0.8.5` and the sanitized task-47 audit. `Ready` means a
version-compatible mechanism exists, not that it is implemented or live-tested.
Private rows remain blocked while `dash` is externally reachable.

| Widget | Page | Data source | Native/custom | Credential | Refresh/cache | Privacy | Resource | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Durham weather and forecast | Home | Open-Meteo | Native `weather` | None | Upstream hourly | Public-safe | Low | Ready | Implemented in first Home pass; Fahrenheit; [docs](https://github.com/glanceapp/glance/blob/v0.8.5/docs/configuration.md#weather) |
| Durham, Nuevo Laredo, San Jose clocks | Home | IANA zones | Native `clock` | None | No request | Public-safe | Negligible | Ready | Implemented in first Home pass |
| Air quality | Home | Unselected provider | Custom API | None/unknown | 15m | Public-safe | Low | Needs clarification | Select documented source and fallback |
| Day, month, year progress | Home | Local time | Local template | None | On page render | Public-safe | Negligible | Needs clarification | Verify safe v0.8.5 template path in task 51 |
| Month calendar | Home | Local calendar | Native `calendar` | None | Upstream fixed | Public-safe | Negligible | Ready | Implemented; it has no event feed support |
| Upcoming calendar events | Home | Provider ICS/CalDAV | Reviewed custom API | Read-only feed/account | 15m | Private-personal | Low | Needs credential | Blocked by task 49 and provider audit |
| Search | Home | DuckDuckGo/approved provider | Native `search` | None | On demand | Public-safe | Negligible | Ready | Implemented with selected bangs |
| Daily bookmarks | Home | Static tracked links | Native `bookmarks` | None | No request | Public-safe | Negligible | Ready | Implemented; not a full Homepage mirror |
| Critical service availability | Home/Hosting | Fixed HTTP monitor set | Native `monitor` | None | 1m | Private-operational | Low | Ready | Implemented on Home and core Hosting after private access boundary; status only, no host metrics |
| Technology briefing | Home/News | Public RSS | Native `rss` | None | 6h | Public-safe | Low | Ready | Implemented on Home; limit 12 |
| Host summary | Hosting | Beszel PocketBase collections via local adapter | Future adapter feeding reviewed `custom-api` | Dedicated readonly user exists in `glance-beszel.env`; adapter code pending Pi validation | 5m target | Private-operational | Low | Needs clarification | Static Go adapter service added disabled by default; keep blocked until Pi tests prove login, field stripping, unavailable/unauthorized/empty/stale failures, and summary JSON from a Glance-equivalent network path |
| Local server stats | Hosting | Glance Agent | Native `server-stats` | New agent | 5m | Private-operational | Medium | Not recommended | New agent conflicts with program boundary |
| Docker containers | Hosting | Docker API | Native `docker-containers` | Docker socket | 5m | Private-operational | High | Not recommended | Raw socket is prohibited |
| Backup age/status | Hosting | Existing backup state | Custom API | Unknown | 15m | Private-operational | Low | Needs clarification | No safe exposed source audited |
| Healthchecks summary | Hosting | Healthchecks | Custom API | Read-only key | 5m | Private-operational | Low | Needs credential | Never expose ping UUIDs |
| Project releases | Hosting/News | GitHub public API | Native `releases` | None/optional token | 6h | Public-safe | Low | Ready | Implemented on core Hosting; release is not update approval |
| Certificate/domain expiry | Hosting | Unselected source | Custom API | Unknown | 24h | Private-operational | Low | Needs clarification | Do not expose domains beyond approved aliases |
| Latest Speedtest result | Network | Speedtest Tracker API | Reviewed custom API | `results:read` token | 5m | Private-personal | Low | Needs credential | Render only selected fields; [API](https://docs.speedtest-tracker.dev/api/responses/results) |
| Speedtest history | Network | Speedtest Tracker API | Reviewed custom API | `results:read` token | 15m | Private-personal | Medium | Needs credential | Use real bounded history only |
| WAN IP/ISP/location | Network | Unselected documented API | Custom API | None/unknown | 1h | Private-personal | Low | Needs clarification | Explicit operator approval recorded; blocked by task 49 |
| Gateway/WAN uptime and RX/TX | Network | Gateway API | Custom API | Read-only account | 5m | Private-operational | Low | Needs service | Gateway/API not audited |
| Local service latency | Network | Fixed HTTP monitor set | Native `monitor` | None | 1m | Private-operational | Low | Ready | Establish sustained baseline before colors |
| AdGuard aggregate DNS stats | Network | AdGuard Home | Native `dns-stats` | Existing admin credentials | 5m | Private-personal | Low | Needs credential | Do not show query/top-domain data by default |
| UniFi counts/health | Network | UniFi API | Reviewed custom API | Read-only account | 5m | Private-operational | Medium | Needs service | Controller/API not audited |
| Tailscale device summary | Network | Tailscale API | Reviewed custom API | Least-privilege token | 5m | Private-personal | Low | Not recommended | Current API-token scope is too broad |
| NetAlertX device status | Network | NetAlertX API | Reviewed custom API | Unknown | 5m | Private-personal | Low | Needs service | Presence/API not audited |
| Plex now playing | Media | Plex | Reviewed custom API | Read token | 5m | Private-personal | Medium | Needs clarification | Plex-first; verify API and image proxying |
| Tautulli activity/history | Media | Tautulli API | Reviewed custom API | API key | 5m/15m | Private-personal | Medium | Needs service | Avoid URL-embedded keys; [API](https://github.com/Tautulli/Tautulli/wiki/Tautulli-API-Reference) |
| Sonarr/Radarr releases/queues | Media | Installed app APIs | Reviewed custom API | API keys | 15m | Private-personal | Low | Needs service | Verify installed versions and OpenAPI docs |
| Immich statistics | Media | Immich API | Reviewed custom API | API key | 24h | Private-personal | Low | Needs service | Verify installation and key scope |
| Trending media/posters | Media | Unselected media source | Custom API | Unknown | 6h | Public-safe | Medium | Needs clarification | Require source/license/image review |
| Steam specials/top sellers | Games | Steam Store endpoint | Reviewed custom API | None | 1h | Public-safe | Medium | Needs clarification | Upstream example exists; Valve API status uncertain |
| Steam profile/recently played | Games | Steam Web API | Reviewed custom API | API key and ID | 1h/15m | Private-personal | Medium | Needs credential | Verify public profile visibility and API fields |
| Steam wishlist discounts | Games | Steam API/store | Reviewed custom API | API key and ID | 1h | Private-personal | Low | Needs credential | Verify documented endpoint and privacy |
| Steam allowlisted friends | Games | Steam Web API | Reviewed custom API | API key, ID, allowlist | 15m | Private-personal | Medium | Needs credential | Never render full friends list |
| Twitch games/creators | Games/Social | Twitch Helix | Reviewed custom API | Client credentials | 1h | Public-safe | Medium | Needs clarification | Only selected creators/categories |
| Gaming/community RSS | Games | Public RSS | Native `rss` | None | 6h | Public-safe | Low | Ready | Communities need operator selection |
| Curated news | News | Public RSS | Native `rss` | None | 6h | Public-safe | Low | Ready | Infrastructure, security, self-hosting, Linux, AI |
| Hacker News/Lobsters | News | Public services | Native widgets | None | 1h | Public-safe | Low | Ready | Limit lists |
| Reddit communities | Social/News | Reddit | Native `reddit` | Optional app credentials | 1h | Public-safe | Low | Needs clarification | Select communities; auth may be needed for rate limits |
| YouTube creators | Social | YouTube | Native `videos` | None | 1h | Public-safe | Medium | Needs clarification | Select creators and thumbnail limit |
| GitHub repositories/releases | Social/News | GitHub | Native `repository`/`releases` | Optional fine-grained token | 6h | Public-safe | Low | Ready | Token only if rate limits require it |
| Karakeep/FreshRSS activity | Social | Existing app APIs | Reviewed custom API | Unknown | 1h | Private-personal | Low | Needs service | API/auth/version not audited |

## Provenance and Constraints

- Native widget behavior: [Glance v0.8.5 configuration](https://github.com/glanceapp/glance/blob/v0.8.5/docs/configuration.md).
- `custom-api` is server-side and version-compatible, but every copied community
  template needs an immutable source commit, request/credential review, HTML
  escaping review, timeout/cache behavior, license, maintenance status, and a
  live failure test before its row moves to implemented.
- Community YAML cannot define `games/*`, `network/*`, or other new widget types.
- `Ready` rows are candidates for their designated future task. They still need
  live testing and may be blocked by the access boundary.
- No row authorizes an adapter, extension container, Docker socket, SSH key,
  raw DNS history, arbitrary JavaScript, or new monitoring stack.
