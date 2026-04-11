#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

[[ -f "${ENV_FILE}" ]] || {
  echo "[ERROR] .env not found at ${ENV_FILE}"
  exit 1
}

set -a
source "${ENV_FILE}"
set +a

: "${USER_NAME:?USER_NAME is not set in .env}"
: "${COMFY_PATH:?COMFY_PATH is not set in .env}"
: "${CONDA_ENV:?CONDA_ENV is not set in .env}"

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

install_miniconda() {
  local target_home="/home/${USER_NAME}"
  local installer="/tmp/miniconda.sh"
  local miniconda_dir="${target_home}/miniconda3"

  log "Installing Miniconda for ${USER_NAME}..."
  wget -O "${installer}" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash "${installer}" -b -p "${miniconda_dir}"
  rm -f "${installer}"

  CONDA_SH="${miniconda_dir}/etc/profile.d/conda.sh"

  if [[ ! -f "${CONDA_SH}" ]]; then
    die "Miniconda installed, but conda.sh was not found at ${CONDA_SH}"
  fi

  log "Miniconda installed at ${miniconda_dir}"
}

detect_or_install_conda() {
  if [[ -n "${CONDA_SH:-}" && -f "${CONDA_SH}" ]]; then
    log "Using conda.sh from .env: ${CONDA_SH}"
    return
  fi

  if command -v conda >/dev/null 2>&1; then
    local detected_base
    detected_base="$(conda info --base 2>/dev/null || true)"

    if [[ -n "${detected_base}" && -f "${detected_base}/etc/profile.d/conda.sh" ]]; then
      CONDA_SH="${detected_base}/etc/profile.d/conda.sh"
      log "Detected conda.sh at ${CONDA_SH}"
      return
    fi
  fi

  warn "Conda not found."

  read -r -p "Do you want to install Miniconda automatically? [y/N] " answer
  if [[ "${answer}" =~ ^[Yy]$ ]]; then
    install_miniconda
  else
    die "Conda is required. Install Miniconda or set CONDA_SH manually in .env"
  fi
}

ensure_user_exists() {
  id "${USER_NAME}" >/dev/null 2>&1 || die "Linux user does not exist: ${USER_NAME}"
}

clone_comfyui() {
  if [[ -d "${COMFY_PATH}/.git" ]]; then
    log "ComfyUI already exists at ${COMFY_PATH}, skipping clone."
    return
  fi

  if [[ -e "${COMFY_PATH}" && ! -d "${COMFY_PATH}/.git" ]]; then
    die "Target path exists but is not a ComfyUI git repository: ${COMFY_PATH}"
  fi

  log "Installing ComfyUI at ${COMFY_PATH}..."
  git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFY_PATH}"
  log "Repository cloned."
}

setup_conda_env() {
  source "${CONDA_SH}"

  if conda env list | awk '{print $1}' | grep -qx "${CONDA_ENV}"; then
    log "Conda environment '${CONDA_ENV}' already exists."
  else
    log "Creating conda environment '${CONDA_ENV}'..."
    conda create -y -n "${CONDA_ENV}" python=3.10
  fi

  conda activate "${CONDA_ENV}"

  log "Installing Python dependencies..."
  cd "${COMFY_PATH}"
  pip install --upgrade pip
  pip install -r requirements.txt
}

update_env_file() {
  python3 - <<PY
from pathlib import Path
import re

env_path = Path("${ENV_FILE}")
text = env_path.read_text(encoding="utf-8")

def set_var(text, key, value):
    pattern = rf'^{key}=.*$'
    replacement = f'{key}="{value}"'
    if re.search(pattern, text, flags=re.MULTILINE):
        return re.sub(pattern, replacement, text, flags=re.MULTILINE)
    return text.rstrip() + f"\\n{replacement}\\n"

text = set_var(text, "CONDA_SH", "${CONDA_SH}")
env_path.write_text(text, encoding="utf-8")
PY

  log ".env updated with detected CONDA_SH=${CONDA_SH}"
}

main() {
  ensure_user_exists
  detect_or_install_conda
  clone_comfyui
  setup_conda_env
  update_env_file

  log "ComfyUI installation finished."
}

main