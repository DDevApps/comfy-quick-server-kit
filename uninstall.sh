#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

echo "== Comfy Quick Server Kit Uninstall =="

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "Warning: .env file not found. Continuing with limited uninstall."
fi

echo
echo "Stopping PM2 panel process if it exists..."
if command -v pm2 >/dev/null 2>&1; then
  pm2 delete comfy-panel >/dev/null 2>&1 || true
  pm2 save >/dev/null 2>&1 || true
  echo "PM2 panel process removed."
else
  echo "PM2 not found. Skipping PM2 cleanup."
fi

echo
echo "Stopping and disabling ComfyUI service..."
# DEPOIS
SERVICE_NAME="${COMFY_SERVICE_NAME:-comfyui}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

sudo systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || true
sudo systemctl disable "$SERVICE_NAME" >/dev/null 2>&1 || true

if [[ -f "$SERVICE_FILE" ]]; then
  echo "Removing systemd service file..."
  sudo rm -f "$SERVICE_FILE"
  sudo systemctl daemon-reload
  echo "Service file removed."
else
  echo "Service file not found. Skipping."
fi

if [[ -n "$LOG_DIR" ]]; then
  echo
  read -rp "Do you want to remove log files in $LOG_DIR? [y/N]: " REMOVE_LOGS
  if [[ "$REMOVE_LOGS" =~ ^[Yy]$ ]]; then
    rm -rf "$LOG_DIR"
    echo "Logs removed."
  else
    echo "Logs kept."
  fi
fi

echo
read -rp "Do you want to remove the local .env file? [y/N]: " REMOVE_ENV
if [[ "$REMOVE_ENV" =~ ^[Yy]$ ]]; then
  rm -f "$ENV_FILE"
  echo ".env removed."
else
  echo ".env kept."
fi

echo
echo "Uninstall complete."
echo "Project files were not deleted."