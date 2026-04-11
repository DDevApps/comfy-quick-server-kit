#!/usr/bin/env bash
set -euo pipefail

echo "==== Comfy Quick Server Kit RESET ===="

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "[WARN] .env not found, using defaults"
  COMFY_SERVICE_NAME="comfyui"
  PANEL_NAME="comfy-quick-panel"
  LOG_DIR="$ROOT_DIR/logs"
fi

echo "[INFO] Stopping services..."

sudo systemctl stop "$COMFY_SERVICE_NAME" 2>/dev/null || true
sudo systemctl disable "$COMFY_SERVICE_NAME" 2>/dev/null || true

pm2 stop "$PANEL_NAME" 2>/dev/null || true
pm2 delete "$PANEL_NAME" 2>/dev/null || true
pm2 save 2>/dev/null || true

echo "[INFO] Removing systemd service..."
sudo rm -f "/etc/systemd/system/${COMFY_SERVICE_NAME}.service"
sudo systemctl daemon-reload

echo "[INFO] Cleaning logs..."
rm -rf "$ROOT_DIR/logs"/* 2>/dev/null || true

echo "[INFO] Reset complete."
echo "Now run: bash install.sh"