#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

err() {
  echo "[ERROR] $*" >&2
}

die() {
  err "$*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

load_env() {
  [[ -f "${ENV_FILE}" ]] || die ".env not found at ${ENV_FILE}"
  # shellcheck disable=SC1090
  set -a
  source "${ENV_FILE}"
  set +a
}

ensure_dir() {
  mkdir -p "$1"
}

replace_template() {
  local template_file="$1"
  local output_file="$2"

  [[ -f "${template_file}" ]] || die "Template not found: ${template_file}"

  local content
  content="$(cat "${template_file}")"

  content="${content//\{\{USER_NAME\}\}/${USER_NAME}}"
  content="${content//\{\{PROJECT_ROOT\}\}/${PROJECT_ROOT}}"
  content="${content//\{\{COMFY_PATH\}\}/${COMFY_PATH}}"
  content="${content//\{\{LOG_DIR\}\}/${LOG_DIR}}"
  content="${content//\{\{COMFY_SERVICE_NAME\}\}/${COMFY_SERVICE_NAME}}"
  content="${content//\{\{CONDA_SH\}\}/${CONDA_SH}}"        # <-- adicionar
  content="${content//\{\{CONDA_ENV\}\}/${CONDA_ENV}}"       # <-- adicionar
  content="${content//\{\{COMFY_PORT\}\}/${COMFY_PORT}}"     # <-- adicionar
  content="${content//\{\{COMFY_ARGS\}\}/${COMFY_ARGS:-}}"   # <-- adicionar

  printf '%s\n' "${content}" > "${output_file}"
}

confirm() {
  local prompt="${1:-Do you want to continue? [y/N]}"
  read -r -p "${prompt} " answer
  [[ "${answer}" =~ ^[Yy]$ ]]
}

notify() {
  local title="${1:-Notification}"
  local message="${2:-}"
  local full="[$(hostname)] ${title}: ${message}"

  # Telegram
  if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d chat_id="${TELEGRAM_CHAT_ID}" \
      -d text="${full}" \
      -d parse_mode="HTML" \
      >/dev/null 2>&1 || warn "Telegram notification failed"
  fi

  # Discord
  if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
    curl -s -X POST "${DISCORD_WEBHOOK_URL}" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"$(echo "${full}" | sed 's/"/\\"/g')\"}" \
      >/dev/null 2>&1 || warn "Discord notification failed"
  fi
}