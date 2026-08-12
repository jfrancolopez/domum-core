#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${GLANCE_IMAGE:-glanceapp/glance:v0.8.5}"

docker run --rm \
  -e DOMUM_DOMAIN="${DOMUM_DOMAIN:-example.com}" \
  -e ADGUARD_WEB_PORT="${ADGUARD_WEB_PORT:-3000}" \
  -v "$ROOT/compose/monitoring/glance:/app/config:ro" \
  "$IMAGE" \
  --config /app/config/glance.yaml \
  config:validate
