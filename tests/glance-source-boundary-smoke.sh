#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGES_DIR="$ROOT_DIR/compose/monitoring/glance/pages"
GLANCE_COMPOSE="$ROOT_DIR/compose/monitoring/glance.yml"
ADAPTER_COMPOSE="$ROOT_DIR/compose/monitoring/glance-beszel-adapter.yml"
BESZEL_COMPOSE="$ROOT_DIR/compose/monitoring/beszel.yml"

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

if (( ${#failures[@]} > 0 )); then
  printf 'glance-source-boundary-smoke failed:\n' >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'glance-source-boundary-smoke ok\n'
