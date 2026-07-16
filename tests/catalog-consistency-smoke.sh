#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="$ROOT_DIR/bin/domum-core"
MAIN_EXAMPLE="$ROOT_DIR/config/domum.conf.example"
BACKUP_EXAMPLE="$ROOT_DIR/config/domum-backup.conf.example"

failures=()

fail() {
  failures+=("$*")
}

catalog_rows() {
  awk '
    /^service_catalog\(\) \{/ { in_fn=1; next }
    in_fn && /^EOF$/ { exit }
    in_fn && /^[^#[:space:]].*\|/ { print }
  ' "$CORE"
}

has_fixed() {
  local needle="$1" file="$2"
  grep -Fq "$needle" "$file"
}

mapfile -t rows < <(catalog_rows)
if (( ${#rows[@]} == 0 )); then
  fail "service_catalog parser extracted 0 rows"
fi

for row in "${rows[@]}"; do
  IFS='|' read -r name enable_var _category _label backup_var compose_rel _probe <<<"$row"

  if [[ -z "$name" || -z "$enable_var" || -z "$compose_rel" ]]; then
    fail "malformed catalog row: $row"
    continue
  fi

  if [[ "$compose_rel" != "-" && ! -f "$ROOT_DIR/$compose_rel" ]]; then
    fail "$name compose file missing: $compose_rel"
  fi

  if ! has_fixed "$enable_var" "$MAIN_EXAMPLE"; then
    fail "$name enable var missing from config/domum.conf.example: $enable_var"
  fi

  if [[ "$backup_var" != "-" && -n "$backup_var" ]]; then
    if ! has_fixed "${backup_var}=\"\${${backup_var}:-" "$CORE"; then
      fail "$name backup var lacks load_cfg default: $backup_var"
    fi
    if ! has_fixed "$backup_var" "$BACKUP_EXAMPLE"; then
      fail "$name backup var missing from config/domum-backup.conf.example: $backup_var"
    fi
  fi
done

extract_update_keys_from_core() {
  grep -oE '[A-Z0-9_]+_(AUTO_UPDATE|UPDATE_DELAY_DAYS)="\$\{[A-Z0-9_]+_(AUTO_UPDATE|UPDATE_DELAY_DAYS):-' "$CORE" \
    | sed -E 's/=.*//' \
    | sort -u
}

extract_update_keys_from_example() {
  grep -oE '^[A-Z0-9_]+_(AUTO_UPDATE|UPDATE_DELAY_DAYS)=' "$MAIN_EXAMPLE" \
    | sed -E 's/=.*//' \
    | sort -u
}

mapfile -t core_update_keys < <(extract_update_keys_from_core)
mapfile -t example_update_keys < <(extract_update_keys_from_example)

while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  fail "update policy key defaulted in bin/domum-core but missing from config/domum.conf.example: $key"
done < <(comm -23 <(printf '%s\n' "${core_update_keys[@]}") <(printf '%s\n' "${example_update_keys[@]}"))

while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  fail "update policy key in config/domum.conf.example but missing load_cfg default: $key"
done < <(comm -13 <(printf '%s\n' "${core_update_keys[@]}") <(printf '%s\n' "${example_update_keys[@]}"))

if (( ${#failures[@]} > 0 )); then
  printf 'catalog-consistency-smoke failed:\n' >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'catalog-consistency-smoke ok (%d services)\n' "${#rows[@]}"
