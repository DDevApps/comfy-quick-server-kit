#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/helpers.sh"
load_env

echo "=== comfy-quick-server-kit doctor ==="

ok_count=0
warn_count=0
fail_count=0

check_ok() {
  echo "[OK] $1"
  ok_count=$((ok_count + 1))
}

check_warn() {
  echo "[WARN] $1"
  warn_count=$((warn_count + 1))
}

check_fail() {
  echo "[FAIL] $1"
  fail_count=$((fail_count + 1))
}

command -v node >/dev/null 2>&1 && check_ok "node found" || check_fail "node missing"
command -v npm >/dev/null 2>&1 && check_ok "npm found" || check_fail "npm missing"
command -v pm2 >/dev/null 2>&1 && check_ok "pm2 found" || check_fail "pm2 missing"
(command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1) && check_ok "python found" || check_fail "python missing"

if command -v nvidia-smi >/dev/null 2>&1; then
  check_ok "nvidia-smi found"
else
  check_warn "nvidia-smi missing (GPU metrics unavailable)"
fi

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

echo
echo "Summary:"
echo "OK:   $ok_count"
echo "WARN: $warn_count"
echo "FAIL: $fail_count"
echo "=== done ==="

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi