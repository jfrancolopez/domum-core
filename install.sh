#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/solosoyfranco/domum-core.git"
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

echo "[domum] Installing prerequisites (curl, git)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates git

echo "[domum] Cloning or updating repo in ${INSTALL_DIR}..."
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  git -C "${INSTALL_DIR}" fetch --all --prune
  if ! git -C "${INSTALL_DIR}" diff --quiet || ! git -C "${INSTALL_DIR}" diff --cached --quiet; then
    echo "[domum] WARN: local changes detected in ${INSTALL_DIR}; not resetting or pulling."
    echo "[domum]       Review with: git -C ${INSTALL_DIR} status"
  else
    git -C "${INSTALL_DIR}" pull --ff-only
  fi
else
  rm -rf "${INSTALL_DIR}"
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

echo "[domum] Installing domum-core CLI to ${BIN_CORE}..."
install -m 0755 "${INSTALL_DIR}/bin/domum-core" "${BIN_CORE}"
install -m 0755 "${INSTALL_DIR}/bin/domum-core-backup" "${BIN_BACKUP}"

echo "[domum] Installing back-compat 'domum' shim -> domum-core..."
cat > "${BIN_SHIM}" <<EOF
#!/usr/bin/env bash
# Back-compat shim: domum -> domum-core
exec ${BIN_CORE} "\$@"
EOF
chmod 0755 "${BIN_SHIM}"

echo "[domum] Creating directories..."
# Standardized secrets path is /etc/domum-core/secrets (was drifting to
# ${INSTALL_DIR}/secrets in older installs).
install -d -m 0700 "${SECRETS_DIR}"
install -d -m 0750 "${STATE_ROOT}"
install -d -m 0750 "${LOG_DIR}"
mkdir -p "${INSTALL_DIR}/data" "${INSTALL_DIR}/logs"

if [[ ! -f "${INSTALL_DIR}/config/domum.conf" ]]; then
  echo "[domum] ERROR: config/domum.conf not found in repo."
  exit 1
fi

# Copy *.conf.example -> *.conf if the live config is missing (never overwrite).
if [[ ! -f "${INSTALL_DIR}/config/domum-backup.conf" \
   && -f "${INSTALL_DIR}/config/domum-backup.conf.example" ]]; then
  echo "[domum] Creating config/domum-backup.conf from example..."
  install -m 0640 "${INSTALL_DIR}/config/domum-backup.conf.example" \
                  "${INSTALL_DIR}/config/domum-backup.conf"
fi

echo "[domum] Done."
echo "Next:"
echo "  sudo domum-core init"
echo "  sudo domum-core apply"
echo
echo "[domum] init/apply were NOT run automatically."
echo "[domum] Run them after reviewing config and any local git drift."
echo "[domum] Done. Re-run anytime with the same curl command."
echo "[domum] For backups/recovery/timers, see docs/SETUP-BACKUPS.md and"
echo "        docs/DISASTER-RECOVERY.md. Install maintenance timers (disabled):"
echo "        sudo domum-core schedule install-maintenance"
