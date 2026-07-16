#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/jfrancolopez/domum-core.git"
INSTALL_DIR_DEFAULT="/opt/domum-core"
SECRETS_DIR="/etc/domum-core/secrets"
STATE_ROOT="/var/lib/domum-core"
LOG_DIR="/var/log/domum-core"
BIN_CORE="/usr/local/bin/domum-core"
BIN_BACKUP="/usr/local/bin/domum-core-backup"
BIN_SHIM="/usr/local/bin/domum"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"
INSTALL_DIR="${INSTALL_DIR:-$INSTALL_DIR_DEFAULT}"

warn_non_https_origin_fetch() {
  local dir="$1" fetch_url
  fetch_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
  case "$fetch_url" in
    https://*) ;;
    *)
      echo "[domum] WARN: origin fetch URL is '${fetch_url:-unset}'; running as root, SSH auth will likely fail." >&2
      echo "[domum] WARN: Recommended (anonymous fetch, SSH push):" >&2
      echo "[domum] WARN:   git -C $dir remote set-url origin https://github.com/jfrancolopez/domum-core.git" >&2
      echo "[domum] WARN:   git -C $dir remote set-url --push origin git@github.com:jfrancolopez/domum-core.git" >&2
      ;;
  esac
}

echo "[domum] Installing prerequisites (curl, git)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates git

echo "[domum] Cloning or updating repo in ${INSTALL_DIR}..."
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  warn_non_https_origin_fetch "${INSTALL_DIR}"
  git -C "${INSTALL_DIR}" fetch --prune origin
  if ! git -C "${INSTALL_DIR}" diff --quiet || ! git -C "${INSTALL_DIR}" diff --cached --quiet; then
    echo "[domum] WARN: local changes detected in ${INSTALL_DIR}; not resetting or pulling."
    echo "[domum]       Review with: git -C ${INSTALL_DIR} status"
  else
    git -C "${INSTALL_DIR}" pull --ff-only
  fi
elif [[ -d "${INSTALL_DIR}" ]]; then
  if [[ -z "$(ls -A "${INSTALL_DIR}")" ]]; then
    rmdir "${INSTALL_DIR}"
    git clone "${REPO_URL}" "${INSTALL_DIR}"
  else
    echo "[domum] ERROR: ${INSTALL_DIR} exists but is not a git checkout." >&2
    echo "[domum] Refusing to delete it. If this is restored data, move it aside first:" >&2
    echo "[domum]     sudo mv ${INSTALL_DIR} ${INSTALL_DIR}.pre-install-\$(date +%Y%m%d)" >&2
    echo "[domum] then re-run this installer and merge your data back afterwards." >&2
    exit 1
  fi
else
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

echo "[domum] Linking domum-core CLI to ${BIN_CORE}..."
# Symlinks (not copies) so `domum-core update` (git pull) updates the
# installed CLI in the same step — no stale-copy window. Trade-off: a broken
# repo state breaks the CLI immediately; acceptable because CI gates main.
chmod 0755 "${INSTALL_DIR}"/bin/*
ln -sf "${INSTALL_DIR}/bin/domum-core" "${BIN_CORE}"
ln -sf "${INSTALL_DIR}/bin/domum-core-backup" "${BIN_BACKUP}"

echo "[domum] Linking back-compat 'domum' shim -> domum-core..."
ln -sf "${INSTALL_DIR}/bin/domum" "${BIN_SHIM}"

echo "[domum] Creating directories..."
# Standardized secrets path is /etc/domum-core/secrets (was drifting to
# ${INSTALL_DIR}/secrets in older installs).
install -d -m 0700 "${SECRETS_DIR}"
install -d -m 0750 "${STATE_ROOT}"
install -d -m 0750 "${LOG_DIR}"
mkdir -p "${INSTALL_DIR}/data" "${INSTALL_DIR}/logs"

if [[ ! -f "${INSTALL_DIR}/config/domum.conf" \
   && -f "${INSTALL_DIR}/config/domum.conf.example" ]]; then
  echo "[domum] Creating config/domum.conf from example..."
  install -m 0640 "${INSTALL_DIR}/config/domum.conf.example" \
                  "${INSTALL_DIR}/config/domum.conf"
elif [[ ! -f "${INSTALL_DIR}/config/domum.conf" ]]; then
  echo "[domum] ERROR: config/domum.conf missing and no example exists."
  exit 1
else
  echo "[domum] Preserving existing config/domum.conf."
fi

# Copy *.conf.example -> *.conf if the live config is missing (never overwrite).
if [[ ! -f "${INSTALL_DIR}/config/domum-backup.conf" \
   && -f "${INSTALL_DIR}/config/domum-backup.conf.example" ]]; then
  echo "[domum] Creating config/domum-backup.conf from example..."
  install -m 0640 "${INSTALL_DIR}/config/domum-backup.conf.example" \
                  "${INSTALL_DIR}/config/domum-backup.conf"
elif [[ -f "${INSTALL_DIR}/config/domum-backup.conf" ]]; then
  echo "[domum] Preserving existing config/domum-backup.conf."
fi

if git -C "${INSTALL_DIR}" ls-files --error-unmatch config/domum.conf >/dev/null 2>&1; then
  echo "[domum] WARN: config/domum.conf is tracked by git; remove it with:"
  echo "             git -C ${INSTALL_DIR} rm --cached config/domum.conf"
elif [[ -f "${INSTALL_DIR}/config/domum.conf" ]]; then
  echo "[domum] NOTE: config/domum.conf is local/untracked and will not be overwritten."
fi
if git -C "${INSTALL_DIR}" ls-files --error-unmatch config/domum-backup.conf >/dev/null 2>&1; then
  echo "[domum] WARN: config/domum-backup.conf is tracked by git; remove it with:"
  echo "             git -C ${INSTALL_DIR} rm --cached config/domum-backup.conf"
elif [[ -f "${INSTALL_DIR}/config/domum-backup.conf" ]]; then
  echo "[domum] NOTE: config/domum-backup.conf is local/untracked and will not be overwritten."
fi

echo "[domum] Done."
echo "Next:"
echo "  sudo domum-core configure --show"
echo "  sudo domum-core configure --validate"
echo "  sudo domum-core init"
echo "  sudo domum-core apply        # only after reviewing config"
echo
echo "[domum] init/apply were NOT run automatically."
echo "[domum] Run them after reviewing config and any local git drift."
echo "[domum] Done. Re-run anytime with the same curl command."
echo "[domum] For backups/recovery/timers, see docs/backups/overview.md and"
echo "        docs/backups/disaster-recovery.md. Install maintenance timers (disabled):"
echo "        sudo domum-core schedule install-maintenance"
