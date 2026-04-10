#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

[[ -f "${ENV_FILE}" ]] || {
  echo "[ERROR] .env not found at ${ENV_FILE}" >&2
  exit 1
}

# shellcheck disable=SC1090
set -a
source "${ENV_FILE}"
set +a

: "${CONDA_SH:?CONDA_SH is not set in .env}"
: "${CONDA_ENV:?CONDA_ENV is not set in .env}"
: "${COMFY_PATH:?COMFY_PATH is not set in .env}"
: "${COMFY_PORT:?COMFY_PORT is not set in .env}"

[[ -f "${CONDA_SH}" ]] || {
  echo "[ERROR] conda.sh not found at ${CONDA_SH}" >&2
  exit 1
}

[[ -d "${COMFY_PATH}" ]] || {
  echo "[ERROR] COMFY_PATH not found at ${COMFY_PATH}" >&2
  exit 1
}

source "${CONDA_SH}"
conda activate "${CONDA_ENV}"

cd "${COMFY_PATH}"

: "${COMFY_ARGS:---listen 0.0.0.0 --lowvram --cache-none --reserve-vram 6 --preview-method none}"

# shellcheck disable=SC2086
exec python main.py \
  --port "${COMFY_PORT}" \
  $COMFY_ARGS