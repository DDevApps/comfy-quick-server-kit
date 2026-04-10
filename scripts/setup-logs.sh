#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
load_env

ensure_dir "${LOG_DIR}"
ensure_dir "${LOG_DIR}/archive"

touch "${LOG_DIR}/comfyui.log"
touch "${LOG_DIR}/comfyui-error.log"

chmod 755 "${LOG_DIR}"
chmod 644 "${LOG_DIR}/comfyui.log" "${LOG_DIR}/comfyui-error.log"

log "Logs prepared at ${LOG_DIR}"