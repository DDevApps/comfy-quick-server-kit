<div align="center">

# Comfy Quick Server Kit

### Lightweight Linux service manager for ComfyUI — built for Ubuntu, remote GPU servers, and local AI machines.

<br>

Running ComfyUI on Linux is easy at first — until you want it to behave like a real service.

You want it to start reliably, survive reboots, expose useful logs, show GPU usage, and be manageable remotely without turning your machine into a DevOps project. Most setups end up as scattered shell commands, half-finished scripts, or heavyweight dashboards that solve the wrong problem.

**Comfy Quick Server Kit** takes a simpler approach: **run ComfyUI as a proper Linux service, keep the control panel lightweight, and make installation practical for real users.**

It uses **systemd** for ComfyUI, **PM2** for the Node.js panel, and a small web UI for the actions that matter: start, stop, restart, logs, GPU stats, and system status. No Docker required. No heavy frontend required. No unnecessary infrastructure.

Built for people who run ComfyUI on:

- local dedicated generation PCs
- home Ubuntu workstations
- rented GPU servers
- cloud GPU instances
- remote Linux boxes accessed from another machine

<br>

[Quick Start](#quick-start) · [Features](#features) · [Requirements](#requirements) · [Configuration](#configuration) · [Troubleshooting](#troubleshooting) · [Roadmap](#roadmap)

</div>

---

## What it does

Comfy Quick Server Kit is designed to solve one specific problem well:

**manage a single ComfyUI installation on Linux with a simple, low-overhead control panel.**

### Core features

- Run ComfyUI with `systemd`
- Run the panel with `PM2`
- Start / stop / restart ComfyUI from the browser
- Check service status
- View recent logs and live logs
- Monitor GPU usage, VRAM, and temperature
- Monitor CPU, RAM, load, and disk usage
- Use a simple `.env`-based configuration
- Install with a beginner-friendly shell script
- Keep everything lightweight and Linux-first

---

## What it does not do

This project is intentionally small and focused.

It is **not**:

- a full ComfyUI installer
- a Docker orchestration platform
- a reverse proxy / SSL manager
- a multi-user admin system
- a Kubernetes-style deployment tool
- a full observability stack

If you want a practical single-machine ComfyUI manager, this is the point.

---

## Why this project exists

A lot of ComfyUI users end up in the same situation:

- ComfyUI works, but only when launched manually
- logs are messy or disappear
- remote access is awkward
- after a reboot, things do not come back cleanly
- GPU usage is hidden unless you SSH in and run commands
- small panel ideas become bloated dashboards

This project exists to keep the solution boring, fast, and useful:

- **systemd** handles the Python service
- **PM2** keeps the panel alive
- **Bash scripts** handle service actions and checks
- **Node.js + Express** exposes a small web interface
- **dotenv** keeps config centralized and editable

That is the whole philosophy.

---

## Features

### Service management

- Start ComfyUI
- Stop ComfyUI
- Restart ComfyUI
- Check whether the service is running
- Keep ComfyUI managed as a real Linux service

### Monitoring

- GPU usage
- VRAM usage
- GPU temperature
- CPU usage / load
- RAM usage
- Disk usage
- system health checks

### Logs

- View recent logs
- View live logs
- Separate service logging from panel process management
- Keep logs accessible without digging through random terminal sessions

### Deployment style

- Linux-first
- Ubuntu-focused
- friendly to remote GPU servers
- simple install flow
- no heavy dependencies
- no complex frontend framework

---

## Intended use

Comfy Quick Server Kit is designed for:

- Ubuntu-based ComfyUI servers
- remote GPU machines
- cloud GPU instances
- local dedicated AI generation machines
- users who want a simple panel instead of a full server stack

---

## Stack

- Node.js
- Express
- PM2
- systemd
- Bash
- dotenv

---

## Requirements

Before installing, you should already have:

- Ubuntu or Ubuntu-based Linux
- ComfyUI already installed
- a working Python environment for ComfyUI
- Node.js installed
- PM2 installed or available to install
- NVIDIA drivers installed if you want GPU monitoring
- `nvidia-smi` available if you want GPU monitoring

### Important note

This project is meant to **manage** ComfyUI, not install every dependency from zero.

That means v1.0 assumes:

- your Linux machine already works
- your GPU drivers already work
- ComfyUI already runs manually
- your Python environment is already valid

---

## Quick Start

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/comfy-quick-server-kit.git
cd comfy-quick-server-kit
```

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your real system paths and configuration.

Run the installer:

```bash
bash install.sh
```

Run diagnostics:

```bash
bash doctor.sh
```

After installation, open the panel in your browser:

```text
http://YOUR_SERVER_IP:3001/?token=YOUR_PANEL_TOKEN
```

If ComfyUI is configured on port `8188`, it will be available at:

```text
http://YOUR_SERVER_IP:8188
```

---

## Configuration

Configuration is handled through a simple `.env` file.

### Example `.env`

```env
USER_NAME=your-user
COMFY_PATH=/home/your-user/ComfyUI
CONDA_SH=/home/your-user/miniconda3/etc/profile.d/conda.sh
CONDA_ENV=comfy

COMFY_PORT=8188
PANEL_PORT=3001
PANEL_TOKEN=change-this-token

LOG_DIR=/home/your-user/logs

COMFY_ARGS=--listen --lowvram --cache-none --reserve-vram 6 --preview-method none
```

### Variable reference

- `USER_NAME` → Linux user that owns and runs ComfyUI
- `COMFY_PATH` → path to your ComfyUI folder
- `CONDA_SH` → path to the `conda.sh` activation script
- `CONDA_ENV` → Conda environment name used by ComfyUI
- `COMFY_PORT` → ComfyUI port
- `PANEL_PORT` → panel port
- `PANEL_TOKEN` → access token for the panel
- `LOG_DIR` → directory where logs are stored
- `COMFY_ARGS` → extra arguments passed to ComfyUI

### Configuration philosophy

The goal is to keep configuration:

- explicit
- readable
- easy to edit
- beginner-friendly
- free from hardcoded paths

---

## Project Structure

```text
comfy-quick-server-kit/
├── panel/
│   ├── package.json
│   └── server.js
├── scripts/
├── templates/
│   └── comfyui.service.template
├── docs/
├── logs/
├── .env.example
├── install.sh
├── doctor.sh
├── update.sh
├── uninstall.sh
└── README.md
```

### Structure overview

- `panel/` → Node.js control panel
- `scripts/` → helper scripts for service control, diagnostics, metrics, and logs
- `templates/` → service templates such as `comfyui.service`
- `docs/` → additional project documentation
- `logs/` → log storage location if used locally in repo-based setups
- `install.sh` → installation script
- `doctor.sh` → diagnostics script
- `update.sh` → update helper
- `uninstall.sh` → uninstall helper

---

## Service Design

This project intentionally separates responsibilities.

### ComfyUI → `systemd`

`systemd` is responsible for:

- starting ComfyUI
- restarting it on failure
- handling boot persistence
- exposing service status
- integrating with normal Linux service flows

### Panel → `PM2`

`PM2` is responsible for:

- keeping the Node.js panel alive
- restarting the panel if it crashes
- making panel startup easier on reboot

### Why this split matters

This avoids mixing concerns.

The Python service stays a normal Linux service.  
The panel stays a lightweight Node process.  
Each part can be restarted or updated independently.

That is exactly what you want on a real Linux machine.

---

## Security Note

The built-in token system is intentionally simple.

It should be treated as **basic access protection for private or self-hosted use**, not as full hardened authentication.

If you expose the panel to the public internet, it is strongly recommended to place it behind at least one of the following:

- a reverse proxy
- firewall restrictions
- IP allowlisting
- a private tunnel
- additional authentication

### Important

Do not treat `?token=...` as enterprise-grade security.  
For v1.0, it is a practical private-server solution.

---

## Useful Commands

### ComfyUI

```bash
sudo systemctl start comfyui
sudo systemctl stop comfyui
sudo systemctl restart comfyui
sudo systemctl status comfyui
journalctl -u comfyui -f
```

### Panel

```bash
pm2 list
pm2 restart comfy-panel
pm2 logs comfy-panel
pm2 save
```

### Diagnostics

```bash
bash doctor.sh
```

---

## Troubleshooting

### Panel shows unauthorized

Make sure you are opening the panel with the correct token:

```text
http://YOUR_SERVER_IP:3001/?token=YOUR_PANEL_TOKEN
```

Also verify that `PANEL_TOKEN` in `.env` matches the value expected by the panel.

---

### Logs do not update

Check that `LOG_DIR` in `.env` matches the actual log output path used by the ComfyUI service.

Also verify that:

- the directory exists
- the service can write to it
- the panel is reading from the same location

---

### Buttons do not start / stop / restart ComfyUI

If the panel triggers `sudo systemctl`, you may need passwordless access for specific commands using `sudo visudo`.

Example:

```text
your-user ALL=(ALL) NOPASSWD: /bin/systemctl start comfyui, /bin/systemctl stop comfyui, /bin/systemctl restart comfyui
```

Adjust the service name if your installation uses a different one.

---

### `nvidia-smi` is missing

GPU monitoring depends on NVIDIA drivers and `nvidia-smi`.

Install the drivers correctly before expecting GPU metrics to work.

---

### ComfyUI works manually but not as a service

Usually this means one of these is wrong:

- `COMFY_PATH`
- `CONDA_SH`
- `CONDA_ENV`
- service user permissions
- working directory in the generated service file

Run:

```bash
bash doctor.sh
```

Then check:

```bash
sudo systemctl status comfyui
journalctl -u comfyui -n 100 --no-pager
```

---

## Roadmap

### v1.0

- install script
- diagnostics script
- ComfyUI service template
- lightweight control panel
- start / stop / restart actions
- recent logs and live logs
- GPU metrics
- basic system metrics

### Later versions

- better authentication
- improved update and uninstall flow
- optional reverse proxy guides
- improved log filtering
- support for more advanced service layouts
- optional multi-instance support

---

## Design Goals

This project is guided by a few simple rules:

### 1. Keep it lightweight

No heavy frontend.  
No unnecessary daemons.  
No Docker requirement.  
No “platform” complexity.

### 2. Keep it practical

This should help real users on real GPU machines, not just look good in screenshots.

### 3. Keep it understandable

A beginner should be able to inspect the stack and understand what is happening:

- ComfyUI is a `systemd` service
- panel is a `PM2` app
- configuration is in `.env`
- diagnostics are in `doctor.sh`

### 4. Do not impact ComfyUI performance

The kit should help manage the machine, not compete with the workload.

---

## License

MIT

---
