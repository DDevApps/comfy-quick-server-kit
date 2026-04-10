#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
load_env

ensure_dir "${LOG_DIR}"
ensure_dir "${LOG_DIR}/archive"

ACTIVE_LOG="${LOG_DIR}/comfyui.log"
ERROR_LOG="${LOG_DIR}/comfyui-error.log"
STAMP="$(date +"%Y-%m-%d_%H-%M-%S")"

if [[ -f "${ACTIVE_LOG}" && -s "${ACTIVE_LOG}" ]]; then
  cp "${ACTIVE_LOG}" "${LOG_DIR}/archive/comfyui-${STAMP}.log"
  : > "${ACTIVE_LOG}"
  log "Active log archived."
else
  warn "Active log is empty or missing."
fi

if [[ -f "${ERROR_LOG}" && -s "${ERROR_LOG}" ]]; then
  cp "${ERROR_LOG}" "${LOG_DIR}/archive/comfyui-error-${STAMP}.log"
  : > "${ERROR_LOG}"
  log "Error log archived."
else
  warn "Error log is empty or missing."
fi