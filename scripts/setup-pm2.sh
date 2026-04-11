#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "[ERROR] .env file not found"
  exit 1
fi

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
load_env

if ! command -v pm2 >/dev/null 2>&1; then
  log "Installing PM2..."
  sudo npm install -g pm2
else
  log "PM2 is already installed."
fi

log "Installing panel dependencies..."
cd "${PROJECT_ROOT}/panel"
npm install

log "Recreating panel process in PM2..."
pm2 delete comfy-panel >/dev/null 2>&1 || true
CONFIG_PATH="${ENV_FILE}" pm2 start server.js --name comfy-panel
pm2 save

log "To enable PM2 on boot, also run:"
echo "pm2 startup"