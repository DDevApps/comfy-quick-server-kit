#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/helpers.sh"
load_env

notify "⚠️ ComfyUI crashed" \
  "Service ${COMFY_SERVICE_NAME} has stopped unexpectedly on $(hostname). Check logs for details."