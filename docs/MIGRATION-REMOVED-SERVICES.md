# Migration: intentionally removed services

`domum-core` is a Home-Assistant-first automation server. It is **not** a media,
AI, camera, or general-purpose homelab host — those workloads belong on the
separate `domum-core-media` (Intel N100) server.

As part of the production hardening pass, the following services were removed
from this project entirely (compose, config, CLI catalog, docs, backups, update
classes, and health checks):

| Service     | Why removed                                  | Belongs on        |
|-------------|----------------------------------------------|-------------------|
| `go2rtc`    | Camera/RTSP restreaming (camera processing)  | `domum-core-media`|
| `frigate`   | NVR / camera object detection                | `domum-core-media`|
| `jellyfin`  | Media server                                 | `domum-core-media`|
| `portainer` | General-purpose container UI (not mission)   | n/a (use the CLI) |

## Your data is NOT deleted automatically

Removing the compose files stops these containers on the next
`sudo domum-core apply` (via `--remove-orphans`), but **named volumes and
bind-mount data are left in place**. Nothing here destroys data.

If — and only if — you are sure you no longer need their data, you can reclaim
space manually:

```bash
# Inspect first
docker volume ls | grep -E 'portainer|jellyfin'
docker ps -a   | grep -E 'go2rtc|frigate|jellyfin|portainer'

# Remove stopped containers (if any remain)
docker rm go2rtc frigate jellyfin portainer 2>/dev/null || true

# Remove named volumes (DESTRUCTIVE — only when you are certain)
docker volume rm domum_portainer-data domum_jellyfin-config domum_jellyfin-cache

# Bind-mount data, if you used any, lived under the old compose dirs:
#   compose/automation/go2rtc, compose/automation/frigate,
#   compose/media/jellyfin  — remove by hand once confirmed unneeded.
```

If you still want camera/media features, deploy them on `domum-core-media`.
