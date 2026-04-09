#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

echo "== Comfy Quick Server Kit Doctor =="
echo

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[FAIL] .env file not found at: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

pass() { echo "[OK]   $1"; }
fail() { echo "[FAIL] $1"; }
warn() { echo "[WARN] $1"; }

echo "Checking configuration..."
[[ -n "$USER_NAME" ]] && pass "USER_NAME is set" || fail "USER_NAME is missing"
[[ -n "$COMFY_PATH" ]] && pass "COMFY_PATH is set" || fail "COMFY_PATH is missing"
[[ -n "$CONDA_SH" ]] && pass "CONDA_SH is set" || fail "CONDA_SH is missing"
[[ -n "$CONDA_ENV" ]] && pass "CONDA_ENV is set" || fail "CONDA_ENV is missing"
[[ -n "$COMFY_PORT" ]] && pass "COMFY_PORT is set" || fail "COMFY_PORT is missing"
[[ -n "$PANEL_PORT" ]] && pass "PANEL_PORT is set" || fail "PANEL_PORT is missing"
[[ -n "$PANEL_TOKEN" ]] && pass "PANEL_TOKEN is set" || fail "PANEL_TOKEN is missing"
[[ -n "$LOG_DIR" ]] && pass "LOG_DIR is set" || fail "LOG_DIR is missing"

echo
echo "Checking paths..."
[[ -d "$COMFY_PATH" ]] && pass "ComfyUI directory exists: $COMFY_PATH" || fail "ComfyUI directory not found: $COMFY_PATH"
[[ -f "$CONDA_SH" ]] && pass "conda.sh exists: $CONDA_SH" || fail "conda.sh not found: $CONDA_SH"
[[ -d "$LOG_DIR" ]] && pass "Log directory exists: $LOG_DIR" || warn "Log directory does not exist yet: $LOG_DIR"

echo
echo "Checking commands..."
command -v node >/dev/null 2>&1 && pass "node found: $(node -v)" || fail "node not found"
command -v npm >/dev/null 2>&1 && pass "npm found: $(npm -v)" || fail "npm not found"
command -v pm2 >/dev/null 2>&1 && pass "pm2 found" || fail "pm2 not found"
command -v systemctl >/dev/null 2>&1 && pass "systemctl found" || fail "systemctl not found"
command -v nvidia-smi >/dev/null 2>&1 && pass "nvidia-smi found" || warn "nvidia-smi not found"
command -v python >/dev/null 2>&1 && pass "python found" || warn "python not found in current shell"

echo
echo "Checking ports..."
ss -ltn | grep -q ":$COMFY_PORT " && pass "ComfyUI port $COMFY_PORT is open" || warn "ComfyUI port $COMFY_PORT is not open"
ss -ltn | grep -q ":$PANEL_PORT " && pass "Panel port $PANEL_PORT is open" || warn "Panel port $PANEL_PORT is not open"

echo
echo "Checking services..."
systemctl list-unit-files | grep -q "^comfyui.service" && pass "comfyui.service exists" || fail "comfyui.service not found"
systemctl is-active --quiet comfyui && pass "comfyui.service is active" || warn "comfyui.service is not active"

echo
echo "Checking PM2..."
if command -v pm2 >/dev/null 2>&1; then
  pm2 list | grep -q "comfy-panel" && pass "PM2 process comfy-panel exists" || warn "PM2 process comfy-panel not found"
else
  warn "Skipping PM2 process check"
fi

echo
echo "Checking ComfyUI files..."
[[ -f "$COMFY_PATH/main.py" ]] && pass "main.py found in ComfyUI path" || fail "main.py not found in ComfyUI path"

echo
echo "Checking logs..."
[[ -f "$LOG_DIR/comfyui.log" ]] && pass "Active log exists" || warn "Active log not found yet"
[[ -f "$LOG_DIR/comfyui-error.log" ]] && pass "Error log exists" || warn "Error log not found yet"

echo
echo "Checking GPU details..."
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total --format=csv,noheader
fi

echo
echo "Doctor check complete."