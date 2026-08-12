#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
tmp="$(mktemp -d /tmp/domum-core-gitleaks.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

git -C "$repo_root" archive --format=tar HEAD | tar -xf - -C "$tmp"
while IFS= read -r path; do
  [[ -f "$repo_root/$path" ]] || continue
  install -D -m 0644 "$repo_root/$path" "$tmp/$path"
done < <(git -C "$repo_root" ls-files)

gitleaks detect --source "$tmp" --no-git --redact --config "$tmp/.gitleaks.toml"
