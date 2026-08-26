#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bin/domum-core
source "$ROOT_DIR/bin/domum-core"

fail() {
  printf 'tailscale-client-source-smoke failed: %s\n' "$*" >&2
  exit 1
}

TAILSCALE_PREFS='{}'
TAILSCALE_STATUS='{"Self":{"ExitNodeOption":false}}'
TAILSCALE_AVAILABLE=1
tailscale() {
  (( TAILSCALE_AVAILABLE == 1 )) || return 1
  if [[ "${1:-}" == "debug" && "${2:-}" == "prefs" ]]; then
    printf '%s\n' "$TAILSCALE_PREFS"
  elif [[ "${1:-}" == "status" && "${2:-}" == "--json" ]]; then
    printf '%s\n' "$TAILSCALE_STATUS"
  else
    return 1
  fi
}

TAILSCALE_PREFS='{"NoSNAT":true,"AdvertiseRoutes":null}'
tailscale_subnet_snat_disabled || fail 'NoSNAT=true was not accepted'
tailscale_host_only_role || fail 'host-only role was not accepted'

TAILSCALE_PREFS='{"NoSNAT":false}'
if tailscale_subnet_snat_disabled; then
  fail 'NoSNAT=false was accepted'
fi

TAILSCALE_PREFS='{"NoSNAT":"true"}'
if tailscale_subnet_snat_disabled; then
  fail 'non-boolean NoSNAT was accepted'
fi

TAILSCALE_PREFS='{"NoSNAT":true'
if tailscale_subnet_snat_disabled; then
  fail 'malformed preference output was accepted'
fi

TAILSCALE_PREFS='{"NoSNAT":true,"AdvertiseRoutes":["192.0.2.0/24"]}'
if tailscale_host_only_role; then
  fail 'advertised subnet route was accepted as host-only'
fi

TAILSCALE_PREFS='{"NoSNAT":true,"AdvertiseRoutes":null}'
TAILSCALE_STATUS='{"Self":{"ExitNodeOption":true}}'
if tailscale_host_only_role; then
  fail 'exit-node role was accepted as host-only'
fi

TAILSCALE_STATUS='{invalid'
if tailscale_host_only_role; then
  fail 'malformed status output was accepted as host-only'
fi

TAILSCALE_AVAILABLE=0
if tailscale_subnet_snat_disabled; then
  fail 'unavailable Tailscale prefs were accepted'
fi

grep -Fq 'tailscale set --snat-subnet-routes=false' "$ROOT_DIR/bin/domum-core" \
  || fail 'host convergence command is missing'
grep -Fq 'sudo tailscale set --snat-subnet-routes=false' "$ROOT_DIR/bin/domum-core" \
  || fail 'checkup repair action is missing'

printf 'tailscale-client-source-smoke ok\n'
