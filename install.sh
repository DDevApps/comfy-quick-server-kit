#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PANEL_DIR="$PROJECT_DIR/panel"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE="$PROJECT_DIR/.env.example"
SERVICE_TEMPLATE="$PROJECT_DIR/templates/comfyui.service.template"
SERVICE_FILE="/etc/systemd/system/comfyui.service"

echo "== Comfy Quick Server Kit Installer =="

if [[ ! -f "$ENV_FILE" ]]; then
  echo
  echo "No .env file found. Creating one now."
  echo

  read -rp "Linux username: " USER_NAME
  read -rp "ComfyUI path: " COMFY_PATH
  read -rp "conda.sh path: " CONDA_SH
  read -rp "Conda environment name [comfy]: " CONDA_ENV
  CONDA_ENV=${CONDA_ENV:-comfy}
  read -rp "ComfyUI port [8188]: " COMFY_PORT
  COMFY_PORT=${COMFY_PORT:-8188}
  read -rp "Panel port [3001]: " PANEL_PORT
  PANEL_PORT=${PANEL_PORT:-3001}
  read -rp "Panel token: " PANEL_TOKEN
  read -rp "Log directory [/home/$USER_NAME/logs]: " LOG_DIR
  LOG_DIR=${LOG_DIR:-/home/$USER_NAME/logs}
  read -rp "Extra ComfyUI args [--listen --lowvram --cache-none --reserve-vram 6 --preview-method none]: " COMFY_ARGS
  COMFY_ARGS=${COMFY_ARGS:---listen --lowvram --cache-none --reserve-vram 6 --preview-method none}

  cat > "$ENV_FILE" <<EOF
USER_NAME=$USER_NAME
COMFY_PATH=$COMFY_PATH
CONDA_SH=$CONDA_SH
CONDA_ENV=$CONDA_ENV
COMFY_PORT=$COMFY_PORT
PANEL_PORT=$PANEL_PORT
PANEL_TOKEN=$PANEL_TOKEN
LOG_DIR=$LOG_DIR
COMFY_ARGS=$COMFY_ARGS
EOF

  echo
  echo ".env file created."
fi

set -a
source "$ENV_FILE"
set +a

echo
echo "Loaded configuration:"
echo "USER_NAME=$USER_NAME"
echo "COMFY_PATH=$COMFY_PATH"
echo "CONDA_ENV=$CONDA_ENV"
echo "COMFY_PORT=$COMFY_PORT"
echo "PANEL_PORT=$PANEL_PORT"
echo "LOG_DIR=$LOG_DIR"
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
echo "Generating comfyui.service..."
TMP_SERVICE="$(mktemp)"
cp "$SERVICE_TEMPLATE" "$TMP_SERVICE"

sed -i "s|{{USER_NAME}}|$USER_NAME|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_PATH}}|$COMFY_PATH|g" "$TMP_SERVICE"
sed -i "s|{{CONDA_SH}}|$CONDA_SH|g" "$TMP_SERVICE"
sed -i "s|{{CONDA_ENV}}|$CONDA_ENV|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_PORT}}|$COMFY_PORT|g" "$TMP_SERVICE"
sed -i "s|{{LOG_DIR}}|$LOG_DIR|g" "$TMP_SERVICE"
sed -i "s|{{COMFY_ARGS}}|$COMFY_ARGS|g" "$TMP_SERVICE"

sudo cp "$TMP_SERVICE" "$SERVICE_FILE"
rm -f "$TMP_SERVICE"

echo
echo "Reloading systemd..."
sudo systemctl daemon-reload
sudo systemctl enable comfyui

echo
echo "Starting ComfyUI service..."
sudo systemctl restart comfyui

echo
echo "Starting panel with PM2..."
cd "$PANEL_DIR"
CONFIG_PATH="$ENV_FILE" pm2 start server.js --name comfy-panel --update-env || true
pm2 restart comfy-panel --update-env || true
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
echo "$USER_NAME ALL=(ALL) NOPASSWD: /bin/systemctl start comfyui, /bin/systemctl stop comfyui, /bin/systemctl restart comfyui"
echo
echo "Installation complete."
echo "Panel URL: http://YOUR_SERVER_IP:$PANEL_PORT/?token=$PANEL_TOKEN"
echo "ComfyUI URL: http://YOUR_SERVER_IP:$COMFY_PORT"