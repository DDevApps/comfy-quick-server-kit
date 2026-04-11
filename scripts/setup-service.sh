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

SERVICE_TEMPLATE="${PROJECT_ROOT}/templates/comfyui.service.template"
SERVICE_TARGET="/etc/systemd/system/${COMFY_SERVICE_NAME}.service"
TEMP_FILE="$(mktemp)"
# Instalar serviço de notificação de falha
NOTIFY_TEMPLATE="${PROJECT_ROOT}/templates/comfyui-notify.service.template"
NOTIFY_TARGET="/etc/systemd/system/${COMFY_SERVICE_NAME}-notify.service"
NOTIFY_TEMP="$(mktemp)"

replace_template "${SERVICE_TEMPLATE}" "${TEMP_FILE}"

log "Installing service to ${SERVICE_TARGET}"
sudo cp "${TEMP_FILE}" "${SERVICE_TARGET}"
rm -f "${TEMP_FILE}"

sudo chmod 644 "${SERVICE_TARGET}"
sudo systemctl daemon-reload
sudo systemctl enable "${COMFY_SERVICE_NAME}"
sudo systemctl restart "${COMFY_SERVICE_NAME}"

log "Service ${COMFY_SERVICE_NAME} installed and restarted."
sudo systemctl status "${COMFY_SERVICE_NAME}" --no-pager || true


if [[ -f "${NOTIFY_TEMPLATE}" ]]; then
  replace_template "${NOTIFY_TEMPLATE}" "${NOTIFY_TEMP}"
  sudo cp "${NOTIFY_TEMP}" "${NOTIFY_TARGET}"
  sudo chmod 644 "${NOTIFY_TARGET}"
  rm -f "${NOTIFY_TEMP}"
  log "Notify service installed at ${NOTIFY_TARGET}"
fi

sudo systemctl daemon-reload