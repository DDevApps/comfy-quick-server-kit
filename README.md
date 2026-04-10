<div align="center">

<br>

```
     ██████╗ ██████╗ ███╗   ███╗███████╗██╗   ██╗    ██╗  ██╗██╗████████╗
    ██╔════╝██╔═══██╗████╗ ████║██╔════╝╚██╗ ██╔╝    ██║ ██╔╝██║╚══██╔══╝
 ██║     ██║   ██║██╔████╔██║█████╗   ╚████╔╝     █████╔╝ ██║   ██║
 ██║     ██║   ██║██║╚██╔╝██║██╔══╝    ╚██╔╝      ██╔═██╗ ██║   ██║
 ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║        ██║       ██║  ██╗██║   ██║
  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝        ╚═╝       ╚═╝  ╚═╝╚═╝   ╚═╝
```

### Lightweight Linux service manager for ComfyUI

**systemd · PM2 · Node.js · Bash · No Docker. No bloat. Just works.**

<br>

[![License: MIT](https://img.shields.io/badge/License-MIT-222?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE)
[![Platform](https://img.shields.io/badge/Ubuntu%20%2F%20Linux-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)]()
[![Node](https://img.shields.io/badge/Node.js%20%E2%89%A518-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)]()
[![Made by DDevApps](https://img.shields.io/badge/made%20by-DDevApps-6366f1?style=for-the-badge&logo=github&logoColor=white)](https://github.com/DDevApps)
[![Stars](https://img.shields.io/github/stars/DDevApps/comfy-quick-server-kit?style=for-the-badge&color=f59e0b&logo=github&logoColor=white)](https://github.com/DDevApps/comfy-quick-server-kit/stargazers)

<br>

[Quick Start](#-quick-start) · [Features](#-features) · [Configuration](#-configuration) · [Notifications](#-notifications) · [Updating ComfyUI](#-updating-comfyui) · [Troubleshooting](#-troubleshooting)

</div>

---

## The problem

Running ComfyUI on Linux is easy at first — until you want it to behave like a real service.

You want it to **start on boot**, **survive crashes**, **expose clean logs**, **show GPU stats remotely**, and be controllable without SSHing in every time. Most setups end up as scattered shell commands, tmux sessions, or heavyweight dashboards that solve the wrong problem.

**Comfy Quick Server Kit** takes a simpler approach:

> Run ComfyUI as a proper Linux service. Keep the control panel lightweight. Make installation practical for real users.

No Docker. No Kubernetes. No Prometheus stack. Just systemd, PM2, Express, and Bash.

---

## ✨ Features

### 🖥️ Control Panel

- Start / Stop / Restart ComfyUI from the browser
- Live service status with uptime display
- One-click **Update ComfyUI** (git pull + pip sync + auto-restart)
- Direct link to open ComfyUI interface

### 📊 Monitoring

| Metric  | Details                                                            |
| ------- | ------------------------------------------------------------------ |
| GPU     | Name, usage %, VRAM used/total, temperature, fan speed, power draw |
| CPU     | Load average (1 / 5 / 15 min)                                      |
| RAM     | Used / Free / Total in GB                                          |
| Disk    | Used, available, total, usage %                                    |
| Process | PID, CPU %, RAM %, thread count                                    |

### 📋 Logs

- Live active log (auto-scrolls, refreshes every second)
- Separate error log viewer
- Archive logs with timestamp
- Browse archived logs directly from the panel
- Clear logs with one click

### 🔔 Notifications

- **Telegram** — get a message when ComfyUI crashes or updates
- **Discord** — same via webhook
- Both can be active simultaneously
- Triggered automatically by systemd on service failure

### ⚙️ Installation

- Interactive installer — asks if you already have ComfyUI or want it installed
- Optionally clones ComfyUI, creates conda env, installs PyTorch + requirements
- Generates the systemd service from a template — no manual editing
- `doctor.sh` diagnoses your setup in seconds

---

## 📋 Requirements

- Ubuntu or Ubuntu-based Linux
- Node.js ≥ 18
- Conda / Miniconda (for the Python environment)
- NVIDIA GPU + drivers + `nvidia-smi` (for GPU monitoring)
- `git` (required if installing ComfyUI via the kit)
- `curl` (required for notifications)

> PM2 is installed automatically by the installer if not present.

---

## 🚀 Quick Start

```bash
git clone https://github.com/DDevApps/comfy-quick-server-kit.git
cd comfy-quick-server-kit
bash install.sh
```

The installer will guide you through everything interactively:

```
== Comfy Quick Server Kit Installer ==

Linux username: myuser
Conda environment name [comfy]:
conda.sh path: /home/myuser/miniconda3/etc/profile.d/conda.sh
ComfyUI port [8188]:
Panel port [3001]:
Panel token: my-secret-token
Log directory [/home/myuser/logs]:

Do you already have ComfyUI installed?
1) Yes, I have it installed
2) No, install it for me

Notification setup (press Enter to skip):
  Telegram bot token:
  Telegram chat ID:
  Discord webhook URL:
```

After installation:

```
Panel URL:   http://YOUR_SERVER_IP:3001/?token=YOUR_TOKEN
ComfyUI URL: http://YOUR_SERVER_IP:8188
```

Run diagnostics at any time:

```bash
bash doctor.sh
```

---

## ⚙️ Configuration

All configuration lives in a single `.env` file at the project root.

```env
# System
USER_NAME=your-user
COMFY_PATH=/home/your-user/ComfyUI
CONDA_SH=/home/your-user/miniconda3/etc/profile.d/conda.sh
CONDA_ENV=comfy

# Ports
COMFY_PORT=8188
PANEL_PORT=3001

# Security
PANEL_TOKEN=change-this-token

# Logs
LOG_DIR=/home/your-user/logs

# ComfyUI launch arguments
COMFY_ARGS=--listen --lowvram --cache-none --reserve-vram 6 --preview-method none

# Service name (change if running multiple instances)
COMFY_SERVICE_NAME=comfyui

# Notifications (optional — leave blank to disable)
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
DISCORD_WEBHOOK_URL=
```

### Variable reference

| Variable              | Description                               |
| --------------------- | ----------------------------------------- |
| `USER_NAME`           | Linux user that owns and runs ComfyUI     |
| `COMFY_PATH`          | Full path to the ComfyUI folder           |
| `CONDA_SH`            | Path to `conda.sh` activation script      |
| `CONDA_ENV`           | Conda environment name for ComfyUI        |
| `COMFY_PORT`          | Port ComfyUI listens on                   |
| `PANEL_PORT`          | Port the control panel listens on         |
| `PANEL_TOKEN`         | Secret token to access the panel          |
| `LOG_DIR`             | Directory where logs are stored           |
| `COMFY_ARGS`          | Arguments passed to `python main.py`      |
| `COMFY_SERVICE_NAME`  | systemd service name (default: `comfyui`) |
| `TELEGRAM_BOT_TOKEN`  | Telegram bot token (optional)             |
| `TELEGRAM_CHAT_ID`    | Telegram chat/user ID (optional)          |
| `DISCORD_WEBHOOK_URL` | Discord webhook URL (optional)            |

---

## 🔔 Notifications

Comfy Quick Server Kit can send notifications to **Telegram**, **Discord**, or both.

Notifications are sent when:

- ⚠️ ComfyUI **crashes** (via systemd `OnFailure`)
- ✅ ComfyUI **updates** successfully (via `update-comfyui.sh`)

### Setting up Telegram

1. Talk to [@BotFather](https://t.me/BotFather) on Telegram and create a bot — you'll get a token like `123456:ABC-DEF...`
2. Send any message to your bot, then open:
   ```
   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   ```
3. Find your `chat.id` in the response
4. Add both values to `.env`:
   ```env
   TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
   TELEGRAM_CHAT_ID=987654321
   ```

### Setting up Discord

1. In your Discord server, go to **Server Settings → Integrations → Webhooks**
2. Create a new webhook and copy the URL
3. Add it to `.env`:
   ```env
   DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
   ```

Both platforms can be active at the same time. Leave either blank to disable it.

---

## 🔄 Updating ComfyUI

From the panel, click **Update ComfyUI**. The kit will:

1. Stop the ComfyUI service
2. Run `git pull origin main` in the ComfyUI directory
3. If new commits are found — reinstall requirements with `pip install -r requirements.txt`
4. Send a notification with the commit hash range (e.g. `a1b2c3d → e4f5g6h`)
5. Restart the service

You can also run it from the terminal:

```bash
bash scripts/update-comfyui.sh
```

> If ComfyUI is already up to date, it will restart the service and exit cleanly without touching pip.

---

## 🗂️ Project Structure

```
comfy-quick-server-kit/
├── panel/
│   ├── package.json
│   └── server.js            ← Express server + embedded panel UI
├── scripts/
│   ├── helpers.sh           ← shared functions (log, notify, load_env...)
│   ├── start-comfyui.sh     ← called by systemd to launch ComfyUI
│   ├── install-comfyui.sh   ← optional: clones + sets up ComfyUI from scratch
│   ├── update-comfyui.sh    ← git pull + pip sync + restart
│   ├── notify-crash.sh      ← called by systemd on service failure
│   ├── setup-service.sh     ← installs the systemd service
│   ├── setup-pm2.sh         ← sets up PM2 for the panel
│   ├── setup-logs.sh        ← creates log directories
│   ├── setup-node.sh        ← node/npm check helper
│   └── archive-logs.sh      ← archives current logs with timestamp
├── templates/
│   ├── comfyui.service.template         ← systemd service template
│   └── comfyui-notify.service.template  ← crash notifier service template
├── docs/
├── .env.example
├── install.sh               ← interactive installer
├── doctor.sh                ← diagnostics
├── update.sh                ← updates panel dependencies + restarts
├── uninstall.sh             ← removes service, PM2 process, optionally logs
└── README.md
```

---

## 🔧 Useful Commands

### ComfyUI service

```bash
sudo systemctl start comfyui
sudo systemctl stop comfyui
sudo systemctl restart comfyui
sudo systemctl status comfyui
journalctl -u comfyui -f
```

### Panel (PM2)

```bash
pm2 list
pm2 restart comfy-panel
pm2 logs comfy-panel
pm2 save
```

### Kit scripts

```bash
bash doctor.sh                      # full diagnostic check
bash update.sh                      # update panel deps + restart
bash uninstall.sh                   # remove service + panel
bash scripts/update-comfyui.sh      # git pull + restart ComfyUI
bash scripts/archive-logs.sh        # archive current logs manually
```

---

## 🛡️ Security

The panel is protected by a token sent as an HTTP header (`x-panel-token`). It is designed for **private self-hosted use**.

If you expose the panel to the public internet, place it behind at least one of:

- a reverse proxy (nginx, Caddy)
- firewall rules or IP allowlisting
- a private tunnel (Tailscale, WireGuard, Cloudflare Access)

**Important:** add passwordless sudo for systemctl to allow panel buttons to work:

```bash
sudo visudo
```

Add this line (adjust service name if needed):

```
your-user ALL=(ALL) NOPASSWD: /bin/systemctl start comfyui, /bin/systemctl stop comfyui, /bin/systemctl restart comfyui
```

---

## 🩺 Troubleshooting

### Panel shows "unauthorized"

Check that the token in the URL matches `PANEL_TOKEN` in `.env`:

```
http://YOUR_IP:3001/?token=YOUR_TOKEN
```

---

### Buttons don't start / stop / restart ComfyUI

The panel calls `sudo systemctl`. You need the passwordless sudo rule above.

---

### ComfyUI works manually but not as a service

Usually one of these is wrong:

- `COMFY_PATH` — does the directory actually exist?
- `CONDA_SH` — is the path to `conda.sh` correct?
- `CONDA_ENV` — does the environment exist?
- service user permissions

Run diagnostics:

```bash
bash doctor.sh
journalctl -u comfyui -n 100 --no-pager
```

---

### Logs don't update

Make sure `LOG_DIR` in `.env` matches the path in your service file. Run `doctor.sh` to check.

---

### GPU shows N/A

`nvidia-smi` must be installed and accessible. Test it:

```bash
nvidia-smi
```

If it fails, your drivers aren't installed or the binary isn't in `PATH`.

---

### Notifications not arriving

Test Telegram manually:

```bash
curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id="<CHAT_ID>" \
  -d text="test"
```

Test Discord manually:

```bash
curl -s -X POST "<WEBHOOK_URL>" \
  -H "Content-Type: application/json" \
  -d '{"content": "test"}'
```

---

## 🗺️ Roadmap

**v1.0 — done**

- [x] Interactive installer with optional ComfyUI installation
- [x] systemd service with crash recovery
- [x] PM2 panel process management
- [x] Start / Stop / Restart / Update from browser
- [x] Live logs + error log viewer + log archiving
- [x] GPU, CPU, RAM, disk, process monitoring
- [x] Telegram + Discord crash + update notifications
- [x] `doctor.sh` diagnostics
- [x] Secure token auth via HTTP header

**Later versions**

- [ ] Reverse proxy setup guide (nginx / Caddy)
- [ ] Custom ComfyUI branch/tag for updates
- [ ] Notification for successful service start (optional)
- [ ] Multi-instance support
- [ ] Log filtering by keyword in the panel
- [ ] Dark/light panel theme toggle

---

## 🏗️ Architecture

```
Browser
   │
   ▼
PM2 → panel/server.js (Express, port 3001)
         │
         ├── GET  /              → serves the panel HTML
         ├── GET  /api/status    → systemctl is-active
         ├── GET  /api/system    → os module (RAM, load)
         ├── GET  /api/gpu       → nvidia-smi
         ├── GET  /api/disk      → df
         ├── GET  /api/process   → ps
         ├── GET  /api/logs/*    → reads log files
         ├── POST /api/start     → systemctl start
         ├── POST /api/stop      → systemctl stop
         ├── POST /api/restart   → systemctl restart
         ├── POST /api/update    → runs update-comfyui.sh
         └── POST /api/*-logs    → archive / clear logs

systemd → comfyui.service
              │
              ├── ExecStart → scripts/start-comfyui.sh
              │                   (conda activate + python main.py)
              ├── Restart=always
              └── OnFailure → comfyui-notify.service
                                   (runs notify-crash.sh → Telegram/Discord)
```

---

## Stack

| Layer          | Technology                             |
| -------------- | -------------------------------------- |
| Python service | systemd                                |
| Panel process  | PM2                                    |
| Panel server   | Node.js + Express                      |
| Configuration  | dotenv                                 |
| Scripts        | Bash                                   |
| Notifications  | curl (Telegram API + Discord Webhooks) |

---

## License

MIT — see [LICENSE](LICENSE)

---

<div align="center">

Built by [DDevApps](https://github.com/DDevApps) · If this saved you time, a ⭐ on GitHub goes a long way.

</div>
