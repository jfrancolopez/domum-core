# Glance Capability Matrix

This matrix is the authorization boundary for the dashboard program. It was
checked against Glance `v0.8.5` and the sanitized task-47 audit. `Ready` means a
version-compatible mechanism exists, not that it is implemented or live-tested.
Private rows require the accepted LAN/Tailscale-only `dash` boundary and remain
explicitly scoped to their approved fields.

| Widget | Page | Data source | Native/custom | Credential | Refresh/cache | Privacy | Resource | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Durham weather and forecast | Home | Open-Meteo | Native `weather` | None | Upstream hourly | Public-safe | Low | Ready | Implemented in first Home pass; Fahrenheit; [docs](https://github.com/glanceapp/glance/blob/v0.8.5/docs/configuration.md#weather) |
| Durham, Nuevo Laredo, San Jose clocks | Home | IANA zones | Native `clock` | None | No request | Public-safe | Negligible | Ready | Implemented in first Home pass |
| Air quality | Home | Open-Meteo Air Quality API | Custom API | None | 30m | Public-safe | Low | Implemented | Durham US AQI plus PM2.5, PM10, and ozone; no account or precise home location |
| Day, month, year progress | Home | Local time | Local template | None | On page render | Public-safe | Negligible | Needs clarification | Verify safe v0.8.5 template path in task 51 |
| Month calendar | Home | Local calendar | Native `calendar` | None | Upstream fixed | Public-safe | Negligible | Ready | Implemented; it has no event feed support |
| Markets pulse | Home | Public market data | Native `markets` | None | Upstream/default | Public-safe | Low | Implemented | SPY, QQQ, BTC, and ETH; informational only, not investment advice |
| Upcoming calendar events | Home | ICS via future local adapter | Reviewed custom API | Read-only secret ICS URL | 15m | Private-personal | Low | Scaffolded | Selected source is ICS; adapter/widget not implemented yet |
| Search | Home | DuckDuckGo/approved provider | Native `search` | None | On demand | Public-safe | Negligible | Ready | Implemented with selected bangs |
| Daily bookmarks | Home | Static tracked links | Native `bookmarks` | None | No request | Public-safe | Negligible | Ready | Implemented; not a full Homepage mirror |
| Critical service availability | Home/Hosting | Fixed HTTP monitor set | Native `monitor` | None | 1m | Private-operational | Low | Ready | Implemented on Home and core Hosting after private access boundary; status only, no host metrics |
| Technology briefing | Home/Technology/News | Public RSS, HN, Lobsters, YouTube, GitHub releases | Native widgets | None | 45m-6h | Public-safe | Low | Implemented | Home summary plus Technology Lab page for self-hosting, security, AI, developer/community signals, and stack releases |
| Host summary | Hosting | Beszel PocketBase collections via local adapter | Custom API | Dedicated readonly user exists in `glance-beszel.env`; adapter implemented | 5m | Private-operational | Low | Implemented | Beszel summary widget added to Hosting page. |
| Local server stats | Hosting | Glance Agent | Native `server-stats` | New agent | 5m | Private-operational | Medium | Not recommended | New agent conflicts with program boundary |
| Docker containers | Hosting | Docker API | Native `docker-containers` | Docker socket | 5m | Private-operational | High | Not recommended | Raw socket is prohibited |
| Backup age/status | Hosting | Host-only `domum-core` backup heartbeat or Healthchecks summary | Custom API | Unknown | 15m | Private-operational | Low | Needs clarification | `/var/lib/domum-core/backups/last-success` must not be mounted into Glance; prefer a reviewed Healthchecks check or separately approved read-only exporter |
| Healthchecks summary | Hosting | Healthchecks Management API v3 `/api/v3/checks/` | Custom API | Project-scoped read-only key | 5m | Private-operational | Low | Needs credential | Read-only responses omit UUIDs and ping URLs; render bounded status/timestamps only; [API](https://healthchecks.io/docs/api/) |
| Project releases | Hosting/News | GitHub public API | Native `releases` | None/optional token | 6h | Public-safe | Low | Ready | Implemented on core Hosting; release is not update approval |
| Certificate/domain expiry | Hosting | Unselected source | Custom API | Unknown | 24h | Private-operational | Low | Needs clarification | Do not expose domains beyond approved aliases |
| Latest Speedtest result | Network | Speedtest Tracker API | Reviewed custom API | `GLANCE_SPEEDTEST_TRACKER_TOKEN` in `glance.env`; `results:read` only | 5m | Private-personal | Low | Implemented | Renders latest download, upload, ping, jitter, packet loss, and timestamp only; [API](https://docs.speedtest-tracker.dev/api/responses/results) |
| Speedtest history | Network | Speedtest Tracker API | Reviewed custom API | `results:read` token | 15m | Private-personal | Medium | Needs credential | Use real bounded history only |
| WAN IP/ISP/location | Network | Unselected documented API | Custom API | None/unknown | 1h | Private-personal | Low | Needs clarification | Public-IP source and exact fields still require a separate operator decision |
| Gateway/WAN uptime and RX/TX | Network | Gateway API | Custom API | Read-only account | 5m | Private-operational | Low | Needs service | Gateway/API not audited |
| Local service latency | Network | Fixed HTTP monitor set | Native `monitor` | None | 1m | Private-operational | Low | Implemented | Compact reachability only; no internal addresses or one-off latency colors |
| AdGuard aggregate DNS stats | Network | AdGuard Home | Native `dns-stats` | `GLANCE_ADGUARD_USERNAME`/`GLANCE_ADGUARD_PASSWORD` in `glance.env` | 5m | Private-personal | Low | Implemented | Secondary deep Network source selected by operator; top domains hidden; aggregate stats only |
| UniFi counts/health | Network | UniFi aggregate health endpoint | Reviewed custom API | `GLANCE_UNIFI_API_URL` and dedicated read-only API key, not Homepage credentials | 5m | Private-operational | Medium | Implemented | Renders subsystem status plus aggregate user/AP/down counts; no client/device detail endpoints |
| Tailscale device summary | Network | Tailscale API | Reviewed custom API | Least-privilege token | 5m | Private-personal | Low | Not recommended | Current API-token scope is too broad |
| NetAlertX device status | Network | NetAlertX API | Reviewed custom API | Unknown | 5m | Private-personal | Low | Needs service | Presence/API not audited |
| Named Home presence | Home | Home Assistant `person.*` states via future local adapter | Reviewed custom API | Glance-specific Home Assistant token and explicit entity allowlist | 1m-5m | Private-personal | Low | Scaffolded | Use display names from env allowlist only; no raw device trackers or network identities |
| Plex now playing | Media | Plex | Reviewed custom API | Read token | 5m | Private-personal | Medium | Needs clarification | Plex-first; verify API and image proxying |
| Tautulli activity/history | Media | Tautulli API | Reviewed custom API | API key | 5m/15m | Private-personal | Medium | Needs service | Avoid URL-embedded keys; [API](https://github.com/Tautulli/Tautulli/wiki/Tautulli-API-Reference) |
| Sonarr/Radarr releases/queues | Media | Installed app APIs | Reviewed custom API | API keys | 15m | Private-personal | Low | Needs service | Verify installed versions and OpenAPI docs |
| Immich statistics | Media | Immich API | Reviewed custom API | API key | 24h | Private-personal | Low | Needs service | Verify installation and key scope |
| Public media discovery | Media | Public RSS and YouTube feeds | Native `rss`/`videos` | None | 45m-1h | Public-safe | Medium | Implemented | Film/TV, books/culture, and selected public video channels; no watch history or personal library data |
| Steam specials | Games | Steam Store `featuredcategories` endpoint | Local custom API template | None | 1h | Public-safe | Medium | Implemented | US-region public specials, bounded to the native collapsible list; no profile, wishlist, friends, or account data |
| Steam profile/recently played | Games | Steam Web API | Reviewed custom API | API key and ID | 1h/15m | Private-personal | Medium | Needs credential | Verify public profile visibility and API fields |
| Steam wishlist discounts | Games | Steam API/store | Reviewed custom API | API key and ID | 1h | Private-personal | Low | Needs credential | Verify documented endpoint and privacy |
| Steam allowlisted friends | Games | Steam Web API | Reviewed custom API | API key, ID, allowlist | 15m | Private-personal | Medium | Needs credential | Never render full friends list |
| Twitch games/creators | Games/Social | Twitch Helix | Reviewed custom API | Client credentials | 1h | Public-safe | Medium | Needs clarification | Only selected creators/categories |
| Gaming/community RSS | Games | Public RSS and YouTube feeds | Native `rss`/`videos` | None | 30m-1h | Public-safe | Medium | Implemented | Public gaming headlines, PC/indie feeds, and design/analysis videos; no account data |
| Curated news | News | Public RSS | Native `rss` | None | 20m-1h | Public-safe | Low | Implemented | World, markets, technology/AI, science, and security feeds |
| Hacker News/Lobsters | Social | Hacker News and Lobsters public endpoints | Native `hacker-news`/`lobsters` | None | 20m | Public-safe | Low | Implemented | Uses Glance-native widgets with bounded top/hot lists; no RSS bridge or account data |
| Reddit communities | Social | Reddit RSS | Native `rss` | None | 45m | Public-safe | Low | Needs clarification | Public RSS returned rate-limit/forbidden responses during source smoke testing; not rendered until a reliable Pi path is verified |
| Public community forums | Social | Home Assistant, Level1Techs, Proxmox RSS | Native `rss` | None | 45m | Public-safe | Low | Implemented | Public forum feeds replace unreliable Reddit bridges; no account or OAuth |
| YouTube creators | Social/Media/Technology | YouTube public feeds | Native `videos` | None | 1h | Public-safe | Medium | Implemented | Selected creators, shorts excluded, bounded card count |
| GitHub repositories/releases | Social/News/Technology | GitHub | Native `repository`/`releases` | Optional fine-grained token | 6h | Public-safe | Low | Implemented | Technology shows bounded public Domum Core commits; releases remain on Home/Hosting/Technology. Token only if rate limits require it |
| Karakeep/FreshRSS activity | Social | Existing app APIs | Reviewed custom API | Unknown | 1h | Private-personal | Low | Needs service | API/auth/version not audited |
| Spotify listening insights | Music/Social/Home | Spotify Web API | Reviewed custom API or local adapter | OAuth client and refresh token | 15m-1h | Private-personal | Medium | Proposed | Read-only scopes only; no playlist writes; local explainable recommendations first |
| YouTube personalized follows/watch insights | Music/Social | YouTube Data API or approved export/source | Reviewed custom API or local adapter | API key and/or OAuth refresh token | 15m-1h | Private-personal | Medium | Proposed | Prefer subscriptions/channel metadata before watch history; no account writes |
| Local recommendations | Music/Social/Home | Derived from approved Spotify/YouTube summaries | Local adapter preferred | Same source credentials | 1h | Private-personal | Medium | Proposed | Explainable local scoring; no raw history to external LLM by default |

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
