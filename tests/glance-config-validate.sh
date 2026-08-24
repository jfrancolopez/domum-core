#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${GLANCE_IMAGE:-glanceapp/glance:v0.8.5}"

docker run --rm \
  -e DOMUM_DOMAIN="${DOMUM_DOMAIN:-example.com}" \
  -e ADGUARD_WEB_PORT="${ADGUARD_WEB_PORT:-3000}" \
  -e GLANCE_SPEEDTEST_TRACKER_TOKEN="${GLANCE_SPEEDTEST_TRACKER_TOKEN:-ci-dummy}" \
  -e GLANCE_ADGUARD_USERNAME="${GLANCE_ADGUARD_USERNAME:-ci-adguard}" \
  -e GLANCE_ADGUARD_PASSWORD="${GLANCE_ADGUARD_PASSWORD:-ci-dummy}" \
  -e GLANCE_UNIFI_URL="${GLANCE_UNIFI_URL:-https://unifi.example.invalid}" \
  -e GLANCE_UNIFI_API_URL="${GLANCE_UNIFI_API_URL:-https://unifi.example.invalid/proxy/network/api/s/default/stat/health}" \
  -e GLANCE_UNIFI_API_KEY="${GLANCE_UNIFI_API_KEY:-ci-dummy}" \
  -e GLANCE_UNIFI_API_HEADER="${GLANCE_UNIFI_API_HEADER:-X-API-Key}" \
  -e GLANCE_UNIFI_API_PATH="${GLANCE_UNIFI_API_PATH:-/proxy/network/api/s/default/stat/health}" \
  -e GLANCE_BESZEL_USERNAME="${GLANCE_BESZEL_USERNAME:-ci@example.invalid}" \
  -e GLANCE_BESZEL_PASSWORD="${GLANCE_BESZEL_PASSWORD:-ci-dummy}" \
  -e GLANCE_BESZEL_SYSTEM_1_LABEL="${GLANCE_BESZEL_SYSTEM_1_LABEL:-domum-core}" \
  -e GLANCE_BESZEL_SYSTEM_1_ID="${GLANCE_BESZEL_SYSTEM_1_ID:-domum-core}" \
  -e GLANCE_BESZEL_SYSTEM_2_LABEL="${GLANCE_BESZEL_SYSTEM_2_LABEL:-media}" \
  -e GLANCE_BESZEL_SYSTEM_2_ID="${GLANCE_BESZEL_SYSTEM_2_ID:-domum-core-media}" \
  -v "$ROOT/compose/monitoring/glance:/app/config:ro" \
  "$IMAGE" \
  --config /app/config/glance.yaml \
  config:validate
