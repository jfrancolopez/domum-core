# Service Template

Use this template when adding new services.

---

## Compose Fragment Template

Create:

    compose/<category>/<service>.yml

Example:

```yaml
services:
  SERVICE_NAME:
    image: IMAGE:TAG
    container_name: SERVICE_NAME
    restart: unless-stopped
    networks:
      - domum-proxy
      - domum-internal
    volumes:
      - ${DOMUM_DIR}/data/SERVICE_NAME:/config
```

---

## Toggle Template

In domum.conf:

    ENABLE_SERVICE_NAME=0

---

## bin/domum Registration

Inside compose_files_for_enabled_services():

```bash
if [[ "${ENABLE_SERVICE_NAME:-0}" == "1" ]]; then
  files+=("$DOMUM_DIR/compose/<category>/SERVICE_NAME.yml")
fi
```

---

## Optional Traefik Labels

If exposing via HTTPS:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.service.rule=Host(`service.ladomum.com`)"
  - "traefik.http.routers.service.entrypoints=websecure"
  - "traefik.http.routers.service.tls.certresolver=cloudflare"
```

---

# Design Rules

- One service per file
- No hardcoded IPs
- Use external networks
- Keep secrets in /etc/domum-core/secrets

