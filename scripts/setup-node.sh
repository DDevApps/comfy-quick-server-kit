#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"

if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  log "Node.js and npm are already installed."
  node -v
  npm -v
  exit 0
fi

log "Installing Node.js 20..."
require_command curl
sudo apt-get update
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

log "Node.js installed:"
node -v
npm -v