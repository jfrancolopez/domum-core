#!/usr/bin/env bash
set -euo pipefail

DOMUM_DIR="${DOMUM_DIR:-/opt/domum-core}"
CFG_FILE="${CFG_FILE:-$DOMUM_DIR/config/domum.conf}"

# shellcheck disable=SC1090
source "$CFG_FILE"

export DOMUM_DOMAIN="${DOMUM_DOMAIN:-ladomum.com}"
export DOMUM_EMAIL="${DOMUM_EMAIL:-admin@ladomum.com}"

# Cloudflare token. Secrets live at /etc/domum-core/secrets (standardized;
# the old $DOMUM_DIR/secrets path was drift and is no longer used).
SECRETS_DIR="${SECRETS_DIR:-/etc/domum-core/secrets}"
if [[ -z "${CF_DNS_API_TOKEN:-}" && -f "$SECRETS_DIR/cloudflare_api_token" ]]; then
  CF_DNS_API_TOKEN="$(cat "$SECRETS_DIR/cloudflare_api_token")"
  export CF_DNS_API_TOKEN
fi

compose_args=(-f "$DOMUM_DIR/compose/base.yml")

# include any enabled files that have night profile services (we include all enabled to keep networks consistent)
if [[ "${ENABLE_TRAEFIK:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/proxy/traefik.yml"); fi
if [[ "${ENABLE_HOME_ASSISTANT:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/automation/home-assistant.yml"); fi
if [[ "${ENABLE_MQTT:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/automation/mqtt.yml"); fi
if [[ "${ENABLE_ZIGBEE2MQTT:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/automation/zigbee2mqtt.yml"); fi
if [[ "${ENABLE_NODERED:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/automation/nodered.yml"); fi
if [[ "${ENABLE_ESP_HOME:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/automation/esphome.yml"); fi
if [[ "${ENABLE_UPTIME_KUMA:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/monitoring/uptime-kuma.yml"); fi
if [[ "${ENABLE_ADGUARD_HOME:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/networking/adguard-home.yml"); fi
if [[ "${ENABLE_TAILSCALE:-0}" == "1" ]]; then compose_args+=(-f "$DOMUM_DIR/compose/security/tailscale.yml"); fi

cmd="${1:-}"
case "$cmd" in
  up)
    docker compose "${compose_args[@]}" --profile night up -d
    ;;
  down)
    docker compose "${compose_args[@]}" --profile night stop
    ;;
  *)
    echo "Usage: domum-night-profile up|down"
    exit 1
    ;;
esac
