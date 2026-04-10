#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/helpers.sh"
load_env

echo "=== comfy-server-kit doctor ==="

check_ok() {
  echo "[OK] $1"
}

check_fail() {
  echo "[FAIL] $1"
}

if command -v node >/dev/null 2>&1; then check_ok "node found"; else check_fail "node missing"; fi
if command -v npm >/dev/null 2>&1; then check_ok "npm found"; else check_fail "npm missing"; fi
if command -v pm2 >/dev/null 2>&1; then check_ok "pm2 found"; else check_fail "pm2 missing"; fi
if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then check_ok "python found"; else check_fail "python missing"; fi
if command -v nvidia-smi >/dev/null 2>&1; then check_ok "nvidia-smi found"; else check_fail "nvidia-smi missing"; fi

[[ -f "${CONDA_SH}" ]] && check_ok "conda.sh found" || check_fail "conda.sh not found: ${CONDA_SH}"
[[ -d "${COMFY_PATH}" ]] && check_ok "COMFY_PATH found" || check_fail "COMFY_PATH not found: ${COMFY_PATH}"
[[ -d "${LOG_DIR}" ]] && check_ok "LOG_DIR found" || check_fail "LOG_DIR not found: ${LOG_DIR}"

if systemctl list-unit-files | grep -q "^${COMFY_SERVICE_NAME}.service"; then
  check_ok "service ${COMFY_SERVICE_NAME} exists"
else
  check_fail "service ${COMFY_SERVICE_NAME} does not exist"
fi

if systemctl is-active --quiet "${COMFY_SERVICE_NAME}"; then
  check_ok "service ${COMFY_SERVICE_NAME} is active"
else
  check_fail "service ${COMFY_SERVICE_NAME} is inactive"
fi

if pm2 list | grep -q "comfy-panel"; then
  check_ok "pm2 comfy-panel exists"
else
  check_fail "pm2 comfy-panel not found"
fi

if ss -ltn | grep -q ":${COMFY_PORT} "; then
  check_ok "Comfy port ${COMFY_PORT} is listening"
else
  check_fail "Comfy port ${COMFY_PORT} is not listening"
fi

if ss -ltn | grep -q ":${PANEL_PORT} "; then
  check_ok "panel port ${PANEL_PORT} is listening"
else
  check_fail "panel port ${PANEL_PORT} is not listening"
fi

echo "=== done ==="