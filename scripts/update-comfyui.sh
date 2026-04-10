#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
load_env

: "${COMFY_PATH:?COMFY_PATH is not set in .env}"
: "${CONDA_SH:?CONDA_SH is not set in .env}"
: "${CONDA_ENV:?CONDA_ENV is not set in .env}"
: "${COMFY_SERVICE_NAME:?COMFY_SERVICE_NAME is not set in .env}"

log "Stopping ${COMFY_SERVICE_NAME}..."
sudo systemctl stop "${COMFY_SERVICE_NAME}"

log "Pulling latest ComfyUI..."
cd "${COMFY_PATH}"
git fetch origin
BEFORE=$(git rev-parse HEAD)
git pull origin main
AFTER=$(git rev-parse HEAD)

if [[ "${BEFORE}" == "${AFTER}" ]]; then
  log "Already up to date (${AFTER:0:7}). Restarting anyway."
else
  log "Updated: ${BEFORE:0:7} → ${AFTER:0:7}"

  source "${CONDA_SH}"
  conda activate "${CONDA_ENV}"

  log "Reinstalling requirements..."
  pip install -r requirements.txt --quiet

  notify "ComfyUI updated" \
    "$(hostname): ComfyUI updated ${BEFORE:0:7} → ${AFTER:0:7}"
fi

log "Starting ${COMFY_SERVICE_NAME}..."
sudo systemctl start "${COMFY_SERVICE_NAME}"

log "Update complete."