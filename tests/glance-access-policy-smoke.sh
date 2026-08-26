#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bin/domum-core
source "$ROOT_DIR/bin/domum-core"

fail() {
  printf 'glance-access-policy-smoke failed: %s\n' "$*" >&2
  exit 1
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

printf '%s\n' '{"log-driver":"json-file","userland-proxy":false}' > "$tmp_dir/valid.json"
printf '%s\n' '{"userland-proxy":true}' > "$tmp_dir/true.json"
printf '%s\n' '[]' > "$tmp_dir/array.json"
printf '%s\n' '{invalid' > "$tmp_dir/invalid.json"
docker_daemon_userland_proxy_disabled_in "$tmp_dir/valid.json" || fail 'valid false setting was rejected'
if docker_daemon_userland_proxy_disabled_in "$tmp_dir/true.json"; then
  fail 'true userland-proxy setting was accepted'
fi
if docker_daemon_userland_proxy_disabled_in "$tmp_dir/array.json"; then
  fail 'non-object daemon JSON was accepted'
fi
if docker_daemon_userland_proxy_disabled_in "$tmp_dir/invalid.json"; then
  fail 'invalid daemon JSON was accepted'
fi

printf '%s\n' old > "$tmp_dir/destination"
printf '%s\n' new > "$tmp_dir/source"
chmod 0600 "$tmp_dir/destination"
before_metadata="$(stat -c '%a %u %g' "$tmp_dir/destination")"
install_preserving_mode_owner "$tmp_dir/source" "$tmp_dir/destination" || fail 'mode/owner-preserving install failed'
after_metadata="$(stat -c '%a %u %g' "$tmp_dir/destination")"
[[ "$before_metadata" == "$after_metadata" ]] || fail 'daemon file metadata changed'
[[ "$(<"$tmp_dir/destination")" == "new" ]] || fail 'replacement content was not installed'
if install_preserving_mode_owner "$tmp_dir/missing-source" "$tmp_dir/destination" 2>/dev/null; then
  fail 'missing replacement source was accepted'
fi
[[ "$(<"$tmp_dir/destination")" == "new" ]] || fail 'failed replacement changed destination content'

LIVE_CONTAINER_ID="test-container"
LIVE_SOURCERANGE=""
LIVE_MIDDLEWARES=""
DOCKER_BIN="$(command -v docker)"
docker() {
  if [[ "${1:-}" != "inspect" || "${2:-}" != "--format" || "${4:-}" != "glance" ]]; then
    command "$DOCKER_BIN" "$@"
    return
  fi
  case "${3:-}" in
    *'.Id'*) printf '%s\n' "$LIVE_CONTAINER_ID" ;;
    *'sourcerange'*) printf '%s\n' "$LIVE_SOURCERANGE" ;;
    *'routers.glance.middlewares'*) printf '%s\n' "$LIVE_MIDDLEWARES" ;;
    *) return 1 ;;
  esac
}

run_policy_check() {
  CHECKUP_WARNINGS=()
  CHECKUP_HEALTHY=()
  CHECKUP_ACTIONS=()
  ENABLE_GLANCE=1
  DOMUM_GLANCE_LAN_CIDR="192.0.2.0/24"
  export ENABLE_GLANCE DOMUM_GLANCE_LAN_CIDR
  checkup_glance_access_policy
}

LIVE_SOURCERANGE="192.0.2.0/24,100.64.0.0/10"
LIVE_MIDDLEWARES="glance-private@docker,glanceEmbedHeaders@file"
run_policy_check
(( ${#CHECKUP_WARNINGS[@]} == 0 )) || fail 'correct live labels produced a warning'
(( ${#CHECKUP_HEALTHY[@]} == 1 )) || fail 'correct live labels were not healthy'

LIVE_SOURCERANGE="198.51.100.0/24,100.64.0.0/10"
run_policy_check
(( ${#CHECKUP_WARNINGS[@]} == 1 )) || fail 'stale LAN CIDR was not detected'
output="$(printf '%s\n' "${CHECKUP_WARNINGS[@]}" "${CHECKUP_ACTIONS[@]}")"
[[ "$output" != *"192.0.2.0/24"* && "$output" != *"198.51.100.0/24"* ]] || fail 'private CIDR leaked into diagnostics'

LIVE_SOURCERANGE="192.0.2.0/24,1100.64.0.0/10"
run_policy_check
(( ${#CHECKUP_WARNINGS[@]} == 1 )) || fail 'malformed Tailscale range was accepted'

LIVE_SOURCERANGE="192.0.2.0/24,100.64.0.0/10"
LIVE_MIDDLEWARES="glanceEmbedHeaders@file"
run_policy_check
(( ${#CHECKUP_WARNINGS[@]} == 1 )) || fail 'missing private middleware was accepted'

# These mocks are called indirectly by checkup_docker_userland_proxy.
# shellcheck disable=SC2317
docker_daemon_userland_proxy_disabled() { return 1; }
# shellcheck disable=SC2317
docker_daemon_restart_needed() { return 0; }
CHECKUP_WARNINGS=()
CHECKUP_HEALTHY=()
CHECKUP_ACTIONS=()
checkup_docker_userland_proxy
[[ " ${CHECKUP_ACTIONS[*]} " == *" sudo domum-core init "* ]] || fail 'unsafe daemon config did not recommend init'
[[ " ${CHECKUP_ACTIONS[*]} " != *" sudo systemctl restart docker "* ]] || fail 'unsafe daemon config recommended a Docker restart'

# shellcheck disable=SC2317
docker_daemon_userland_proxy_disabled() { return 0; }
CHECKUP_WARNINGS=()
CHECKUP_HEALTHY=()
CHECKUP_ACTIONS=()
checkup_docker_userland_proxy
[[ " ${CHECKUP_ACTIONS[*]} " == *" sudo systemctl restart docker "* ]] || fail 'valid newer daemon config did not recommend restart'

empty_render="$(
  DOMUM_DOMAIN=example.com DOMUM_GLANCE_LAN_CIDR='' \
    docker compose -f "$ROOT_DIR/compose/monitoring/glance.yml" --profile core \
    config --no-env-resolution
)"
grep -Fq \
  'traefik.http.middlewares.glance-private.ipallowlist.sourcerange: 100.64.0.0/10' \
  <<< "$empty_render" \
  || fail 'empty LAN CIDR did not render an exact Tailscale range'

populated_render="$(
  DOMUM_DOMAIN=example.com DOMUM_GLANCE_LAN_CIDR='192.0.2.0/24' \
    docker compose -f "$ROOT_DIR/compose/monitoring/glance.yml" --profile core \
    config --no-env-resolution
)"
grep -Fq \
  'traefik.http.middlewares.glance-private.ipallowlist.sourcerange: 192.0.2.0/24,100.64.0.0/10' \
  <<< "$populated_render" \
  || fail 'populated LAN CIDR did not render the exact combined range'

printf 'glance-access-policy-smoke ok\n'
