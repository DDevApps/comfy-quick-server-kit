#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
load_env

: "${CONDA_SH:?CONDA_SH is not set in .env}"
: "${CONDA_ENV:?CONDA_ENV is not set in .env}"
: "${COMFY_PATH:?COMFY_PATH is not set in .env}"

log "Installing ComfyUI at ${COMFY_PATH}..."

if [[ -d "${COMFY_PATH}" ]]; then
  warn "Directory ${COMFY_PATH} already exists. Skipping clone."
else
  git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFY_PATH}"
  log "Repository cloned."
fi

source "${CONDA_SH}"

if conda env list | grep -q "^${CONDA_ENV} "; then
  warn "Conda env '${CONDA_ENV}' already exists. Skipping creation."
else
  log "Creating conda environment '${CONDA_ENV}'..."
  conda create -y -n "${CONDA_ENV}" python=3.11
  log "Conda env created."
fi

conda activate "${CONDA_ENV}"

log "Installing PyTorch (CUDA 12.1)..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

log "Installing ComfyUI requirements..."
pip install -r "${COMFY_PATH}/requirements.txt"

log "ComfyUI installed successfully at ${COMFY_PATH}"