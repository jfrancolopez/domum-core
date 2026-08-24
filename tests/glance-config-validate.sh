#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${GLANCE_IMAGE:-glanceapp/glance:v0.8.5}"

docker run --rm \
  -e DOMUM_DOMAIN="${DOMUM_DOMAIN:-example.com}" \
  -e GLANCE_SPEEDTEST_TRACKER_TOKEN="${GLANCE_SPEEDTEST_TRACKER_TOKEN:-ci-dummy}" \
  -e GLANCE_ADGUARD_USERNAME="${GLANCE_ADGUARD_USERNAME:-ci-adguard}" \
  -e GLANCE_ADGUARD_PASSWORD="${GLANCE_ADGUARD_PASSWORD:-ci-dummy}" \
  -e GLANCE_UNIFI_API_URL="${GLANCE_UNIFI_API_URL:-https://unifi.example.invalid/proxy/network/api/s/default/stat/health}" \
  -e GLANCE_UNIFI_API_KEY="${GLANCE_UNIFI_API_KEY:-ci-dummy}" \
  -e GLANCE_UNIFI_API_HEADER="${GLANCE_UNIFI_API_HEADER:-X-API-Key}" \
  -v "$ROOT/compose/monitoring/glance:/app/config:ro" \
  "$IMAGE" \
  --config /app/config/glance.yaml \
  config:validate
