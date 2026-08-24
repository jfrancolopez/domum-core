#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGES_DIR="$ROOT_DIR/compose/monitoring/glance/pages"
GLANCE_COMPOSE="$ROOT_DIR/compose/monitoring/glance.yml"
ADAPTER_COMPOSE="$ROOT_DIR/compose/monitoring/glance-beszel-adapter.yml"
BESZEL_COMPOSE="$ROOT_DIR/compose/monitoring/beszel.yml"
NETWORK_PAGE="$PAGES_DIR/network.yml"

failures=()

has_fixed() {
  local needle="$1" file="$2"
  grep -Fq -- "$needle" "$file"
}

require_fixed() {
  local needle="$1" file="$2" message="$3"
  if ! has_fixed "$needle" "$file"; then
    failures+=("$message")
  fi
}

require_absent() {
  local needle="$1" file="$2" message="$3"
  if has_fixed "$needle" "$file"; then
    failures+=("$message")
  fi
}

while IFS= read -r -d '' page; do
  require_absent \
    'style: detailed-list' \
    "$page" \
    "RSS image-bearing style remains in ${page#"$ROOT_DIR"/}"
done < <(printf '%s\0' "$PAGES_DIR"/*.yml)

require_fixed 'glance-beszel-backend' "$GLANCE_COMPOSE" \
  'Glance is not attached to the private Beszel backend network'
require_fixed 'internal: true' "$GLANCE_COMPOSE" \
  'Glance Compose file does not declare the Beszel backend as internal'
require_fixed 'glance-beszel-backend' "$ADAPTER_COMPOSE" \
  'Beszel adapter is not attached to the private backend network'
require_absent '- domum-proxy' "$ADAPTER_COMPOSE" \
  'Beszel adapter still joins the broad domum-proxy network'
require_fixed 'glance-beszel-backend' "$BESZEL_COMPOSE" \
  'Beszel is not attached to the private adapter network'
require_absent 'allow-insecure: true' "$NETWORK_PAGE" \
  'UniFi custom API has re-enabled insecure TLS'

reserved_vars=(
  GLANCE_HEALTHCHECKS_URL GLANCE_HEALTHCHECKS_API_KEY
  GLANCE_CALENDAR_ICS_URL GLANCE_CALENDAR_LOOKAHEAD_DAYS GLANCE_CALENDAR_MAX_EVENTS
  GLANCE_HOMEASSISTANT_URL GLANCE_HOMEASSISTANT_TOKEN
  GLANCE_PRESENCE_PERSON_1_NAME GLANCE_PRESENCE_PERSON_1_ENTITY
  GLANCE_PRESENCE_PERSON_2_NAME GLANCE_PRESENCE_PERSON_2_ENTITY
  GLANCE_PRESENCE_PERSON_3_NAME GLANCE_PRESENCE_PERSON_3_ENTITY
  GLANCE_PRESENCE_PERSON_4_NAME GLANCE_PRESENCE_PERSON_4_ENTITY
  GLANCE_TAUTULLI_URL GLANCE_TAUTULLI_API_KEY GLANCE_PLEX_URL GLANCE_PLEX_TOKEN
  GLANCE_STEAM_API_KEY GLANCE_STEAM_ID64 GLANCE_STEAM_COUNTRY
  GLANCE_TWITCH_CLIENT_ID GLANCE_TWITCH_CLIENT_SECRET
  GLANCE_SPOTIFY_CLIENT_ID GLANCE_SPOTIFY_CLIENT_SECRET GLANCE_SPOTIFY_REFRESH_TOKEN
  GLANCE_YOUTUBE_CLIENT_ID GLANCE_YOUTUBE_CLIENT_SECRET
  GLANCE_YOUTUBE_REFRESH_TOKEN GLANCE_YOUTUBE_API_KEY GLANCE_GITHUB_TOKEN
  GLANCE_UNIFI_URL GLANCE_UNIFI_API_PATH
)

for variable in "${reserved_vars[@]}"; do
  require_fixed "- ${variable}=" "$GLANCE_COMPOSE" \
    "Reserved Glance variable is not cleared: $variable"
done

if (( ${#failures[@]} > 0 )); then
  printf 'glance-source-boundary-smoke failed:\n' >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'glance-source-boundary-smoke ok\n'
