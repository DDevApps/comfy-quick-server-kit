#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PANEL_DIR="$PROJECT_DIR/panel"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE="$PROJECT_DIR/.env.example"
SERVICE_TEMPLATE="$PROJECT_DIR/templates/comfyui.service.template"

echo "== Comfy Quick Server Kit Installer =="

on_error() {
  echo ""
  echo "[ERROR] Installation failed."
  echo "[INFO] Running reset..."
  bash reset.sh || true
  echo "[INFO] Fix the issue and run install.sh again."
  exit 1
}

trap 'on_error' ERR

validate_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo
  echo "No .env file found. Creating one now."
  echo


  USER_NAME="${USER_NAME:-}"

  while [[ -z "${USER_NAME// }" ]]; do
    echo "[ERROR] Linux username cannot be empty."
    read -rp "Linux username: " USER_NAME
  done
  read -rp "Conda environment name [comfy]: " CONDA_ENV
  CONDA_ENV="${CONDA_ENV:-comfy}"

  read -rp "conda.sh path (leave empty to auto-detect or install later): " CONDA_SH

  while ! validate_port "$COMFY_PORT"; do
    echo "[ERROR] Invalid ComfyUI port. Use a number between 1 and 65535."
    read -rp "ComfyUI port [8188]: " COMFY_PORT
    COMFY_PORT="${COMFY_PORT:-8188}"
  done

  while ! validate_port "$PANEL_PORT"; do
    echo "[ERROR] Invalid panel port. Use a number between 1 and 65535."
    read -rp "Panel port [3001]: " PANEL_PORT
    PANEL_PORT="${PANEL_PORT:-3001}"
  done

  echo
echo "Panel access token"
echo "This token protects the web panel."
echo "Choose a strong secret, like a password."
echo "Recommended: at least 12 characters with letters and numbers."
echo "Example: myPanelSecure2026"
echo

while true; do
  read -rsp "Panel token: " PANEL_TOKEN
  echo
  PANEL_TOKEN="${PANEL_TOKEN//[$'\r\n']}"
  
  if [[ -z "$PANEL_TOKEN" ]]; then
    echo "[ERROR] Panel token cannot be empty."
    continue
  fi

  if [[ ${#PANEL_TOKEN} -lt 8 ]]; then
    echo "[WARN] Token is too short. Use at least 8 characters."
    read -rp "Use it anyway? [y/N]: " USE_WEAK_TOKEN
    if [[ ! "$USE_WEAK_TOKEN" =~ ^[Yy]$ ]]; then
      continue
    fi
  fi

  read -rsp "Confirm panel token: " PANEL_TOKEN_CONFIRM
  echo

  if [[ "$PANEL_TOKEN" != "$PANEL_TOKEN_CONFIRM" ]]; then
    echo "[ERROR] Tokens do not match. Try again."
    continue
  fi

  break
done

  read -rp "Log directory [/home/$USER_NAME/logs]: " LOG_DIR
  LOG_DIR="${LOG_DIR:-/home/$USER_NAME/logs}"

  read -rp "Extra ComfyUI args [--listen 0.0.0.0 --lowvram --cache-none --reserve-vram 6 --preview-method none]: " COMFY_ARGS
  COMFY_ARGS="${COMFY_ARGS:---listen 0.0.0.0 --lowvram --cache-none --reserve-vram 6 --preview-method none}"

  read -rp "Comfy service name [comfyui]: " COMFY_SERVICE_NAME
  COMFY_SERVICE_NAME="${COMFY_SERVICE_NAME:-comfyui}"

  echo
  echo "Do you already have ComfyUI installed?"
  select COMFY_CHOICE in "Yes, I have it installed" "No, install it for me"; do
    case "${COMFY_CHOICE}" in
      "Yes, I have it installed")
        read -rp "ComfyUI path: " COMFY_PATH
        while [[ ! -d "$COMFY_PATH" ]]; do
          echo "Directory not found: $COMFY_PATH"
          read -rp "ComfyUI path: " COMFY_PATH
        done
        INSTALL_COMFYUI=false
        break
        ;;
      "No, install it for me")
        read -rp "Where to install ComfyUI [/home/$USER_NAME/ComfyUI]: " COMFY_PATH
        COMFY_PATH="${COMFY_PATH:-/home/$USER_NAME/ComfyUI}"
        INSTALL_COMFYUI=true
        break
        ;;
    esac
  done

  echo
  echo "Notification setup (press Enter to skip):"
  read -rp "  Telegram bot token: " TELEGRAM_BOT_TOKEN
  read -rp "  Telegram chat ID: " TELEGRAM_CHAT_ID
  read -rp "  Discord webhook URL: " DISCORD_WEBHOOK_URL

  cat > "$ENV_FILE" <<EOF
USER_NAME="$USER_NAME"
COMFY_PATH="$COMFY_PATH"
CONDA_SH="$CONDA_SH"
CONDA_ENV="$CONDA_ENV"
COMFY_PORT="$COMFY_PORT"
PANEL_PORT="$PANEL_PORT"
PANEL_TOKEN="$PANEL_TOKEN"
LOG_DIR="$LOG_DIR"
COMFY_ARGS="$COMFY_ARGS"
COMFY_SERVICE_NAME="$COMFY_SERVICE_NAME"
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL"
EOF

  echo
  echo ".env file created."
fi

set -a
source "$ENV_FILE"
set +a

: "${USER_NAME:?Missing USER_NAME in .env}"
: "${COMFY_PATH:?Missing COMFY_PATH in .env}"
: "${CONDA_ENV:?Missing CONDA_ENV in .env}"
: "${COMFY_PORT:?Missing COMFY_PORT in .env}"
: "${PANEL_PORT:?Missing PANEL_PORT in .env}"
: "${PANEL_TOKEN:?Missing PANEL_TOKEN in .env}"
: "${LOG_DIR:?Missing LOG_DIR in .env}"

COMFY_SERVICE_NAME="${COMFY_SERVICE_NAME:-comfyui}"
SERVICE_FILE="/etc/systemd/system/${COMFY_SERVICE_NAME}.service"

if [[ "${INSTALL_COMFYUI:-false}" == "true" ]]; then
  echo
  echo "Installing ComfyUI..."
  bash "$PROJECT_DIR/scripts/install-comfyui.sh"
fi

set -a
source "$ENV_FILE"
set +a

: "${CONDA_SH:?Missing CONDA_SH in .env after ComfyUI install}"

echo
echo "Loaded configuration:"
echo "USER_NAME=$USER_NAME"
echo "COMFY_PATH=$COMFY_PATH"
echo "CONDA_ENV=$CONDA_ENV"
echo "COMFY_PORT=$COMFY_PORT"
echo "PANEL_PORT=$PANEL_PORT"
echo "LOG_DIR=$LOG_DIR"
echo "COMFY_SERVICE_NAME=$COMFY_SERVICE_NAME"
echo

mkdir -p "$LOG_DIR"
mkdir -p "$LOG_DIR/archive"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is not installed."
  echo "Install Node.js first, then run this installer again."
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is not installed."
  exit 1
fi

if ! command -v pm2 >/dev/null 2>&1; then
  echo "PM2 not found. Installing globally..."
  sudo npm install -g pm2
fi

echo
echo "Installing panel dependencies..."
cd "$PANEL_DIR"
npm install
cd "$PROJECT_DIR"

echo
echo "Generating ${COMFY_SERVICE_NAME}.service..."
TMP_SERVICE="$(mktemp)"
cp "$SERVICE_TEMPLATE" "$TMP_SERVICE"

sed -i "s|{{USER_NAME}}|$USER_NAME|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_PATH}}|$COMFY_PATH|g" "$TMP_SERVICE"
sed -i "s|{{CONDA_SH}}|$CONDA_SH|g" "$TMP_SERVICE"
sed -i "s|{{CONDA_ENV}}|$CONDA_ENV|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_PORT}}|$COMFY_PORT|g" "$TMP_SERVICE"
sed -i "s|{{LOG_DIR}}|$LOG_DIR|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_ARGS}}|$COMFY_ARGS|g" "$TMP_SERVICE"
sed -i "s|{{PROJECT_ROOT}}|$PROJECT_DIR|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_SERVICE_NAME}}|$COMFY_SERVICE_NAME|g" "$TMP_SERVICE"

sudo cp "$TMP_SERVICE" "$SERVICE_FILE"
rm -f "$TMP_SERVICE"

echo
echo "Reloading systemd..."
sudo systemctl daemon-reload
sudo systemctl enable "$COMFY_SERVICE_NAME"

echo
echo "Starting ComfyUI service..."
sudo systemctl restart "$COMFY_SERVICE_NAME"

echo
echo "Starting panel with PM2..."
cd "$PANEL_DIR"
echo
echo "Starting panel with PM2..."
cd "$PANEL_DIR"

if pm2 describe comfy-panel >/dev/null 2>&1; then
  CONFIG_PATH="$ENV_FILE" pm2 restart comfy-panel --update-env
else
  CONFIG_PATH="$ENV_FILE" pm2 start server.js --name comfy-panel --update-env
fi

pm2 save
cd "$PROJECT_DIR"
pm2 save
cd "$PROJECT_DIR"

echo
echo "PM2 startup configuration:"
pm2 startup

echo
echo "IMPORTANT:"
echo "To allow panel start/stop/restart buttons to control ComfyUI without a password,"
echo "add the following line using: sudo visudo"
echo
echo "$USER_NAME ALL=(ALL) NOPASSWD: /bin/systemctl start $COMFY_SERVICE_NAME, /bin/systemctl stop $COMFY_SERVICE_NAME, /bin/systemctl restart $COMFY_SERVICE_NAME"
echo
echo "Installation complete."
echo "Panel URL: http://YOUR_SERVER_IP:$PANEL_PORT/?token=$PANEL_TOKEN"
echo "ComfyUI URL: http://YOUR_SERVER_IP:$COMFY_PORT"