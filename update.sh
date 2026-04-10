#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PANEL_DIR="$PROJECT_DIR/panel"
ENV_FILE="$PROJECT_DIR/.env"

echo "== Comfy Quick Server Kit Update =="

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

echo
echo "Using configuration:"
echo "COMFY_PATH=$COMFY_PATH"
echo "PANEL_PORT=$PANEL_PORT"
echo "COMFY_PORT=$COMFY_PORT"
echo "LOG_DIR=$LOG_DIR"

echo
echo "Installing/updating panel dependencies..."
cd "$PANEL_DIR"
npm install
cd "$PROJECT_DIR"

echo
echo "Reloading systemd..."
sudo systemctl daemon-reload

echo
echo "Restarting ComfyUI..."
sudo systemctl restart "${COMFY_SERVICE_NAME:-comfyui}"

echo
echo "Restarting panel with PM2..."
cd "$PANEL_DIR"
CONFIG_PATH="$ENV_FILE" pm2 restart comfy-panel --update-env
pm2 save
cd "$PROJECT_DIR"

echo
echo "Update complete."
echo "Panel: http://YOUR_SERVER_IP:$PANEL_PORT/?token=$PANEL_TOKEN"
echo "ComfyUI: http://YOUR_SERVER_IP:$COMFY_PORT"