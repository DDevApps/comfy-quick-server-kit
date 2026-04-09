require("dotenv").config({
  path:
    process.env.CONFIG_PATH || require("path").join(__dirname, "..", ".env"),
});

const express = require("express");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

const app = express();

const PANEL_PORT = process.env.PANEL_PORT || 3001;
const PANEL_TOKEN = process.env.PANEL_TOKEN || "change-this-token";
const COMFY_PORT = process.env.COMFY_PORT || 8188;
const LOG_DIR = process.env.LOG_DIR || "/tmp/comfy-quick-server-kit-logs";

const LOG_FILE = path.join(LOG_DIR, "comfyui.log");
const ERROR_LOG_FILE = path.join(LOG_DIR, "comfyui-error.log");
const LOG_ARCHIVE_DIR = path.join(LOG_DIR, "archive");

app.use(express.json());

function auth(req, res, next) {
  const token = req.query.token || req.headers["x-panel-token"];
  if (token !== PANEL_TOKEN) {
    return res.status(401).send("unauthorized");
  }
  next();
}

function run(cmd) {
  return new Promise((resolve) => {
    exec(cmd, (err, stdout, stderr) => {
      resolve({
        ok: !err,
        stdout: (stdout || "").trim(),
        stderr: (stderr || "").trim(),
      });
    });
  });
}

function tailFile(filePath, maxBytes = 120000) {
  try {
    if (!fs.existsSync(filePath)) return "";
    const stat = fs.statSync(filePath);
    const size = stat.size;
    const start = Math.max(0, size - maxBytes);
    const fd = fs.openSync(filePath, "r");
    const buffer = Buffer.alloc(size - start);
    fs.readSync(fd, buffer, 0, buffer.length, start);
    fs.closeSync(fd);
    return buffer.toString("utf8");
  } catch (e) {
    return `Erro lendo log: ${e.message}`;
  }
}

function ensureArchiveDir() {
  if (!fs.existsSync(LOG_ARCHIVE_DIR)) {
    fs.mkdirSync(LOG_ARCHIVE_DIR, { recursive: true });
  }
}

app.get("/", auth, async (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Comfy Panel</title>
  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background: #0b1220;
      color: #e5e7eb;
    }
    .container {
      max-width: 1300px;
      margin: 0 auto;
      padding: 20px;
    }
    h1, h2 {
      margin: 0 0 12px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 16px;
    }
    .grid-3 {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 16px;
    }
    .card {
      background: #111827;
      border: 1px solid #1f2937;
      border-radius: 14px;
      padding: 16px;
      box-sizing: border-box;
    }
    .actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      margin-top: 12px;
    }
    button, a.btn {
      background: #2563eb;
      color: #fff;
      border: none;
      border-radius: 10px;
      padding: 10px 14px;
      cursor: pointer;
      text-decoration: none;
      display: inline-block;
    }
    button.danger { background: #b91c1c; }
    button.gray { background: #374151; }
    .badge {
      display: inline-block;
      padding: 6px 10px;
      border-radius: 999px;
      font-weight: bold;
    }
    .online { background: #065f46; }
    .offline { background: #7f1d1d; }
    .warn { background: #92400e; }
    .small {
      color: #9ca3af;
      font-size: 12px;
    }
    pre {
      background: #020617;
      color: #d1fae5;
      padding: 12px;
      border-radius: 10px;
      height: 420px;
      overflow: auto;
      white-space: pre-wrap;
      word-break: break-word;
      margin: 0;
    }
    ul { padding-left: 18px; }
    a.loglink { color: #93c5fd; }
    .metric {
      font-size: 14px;
      line-height: 1.8;
    }
    @media (max-width: 980px) {
      .grid, .grid-3 {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Comfy Panel</h1>
    <p class="small">Controle do ComfyUI, logs e recursos do sistema</p>

    <div class="grid">
      <div class="card">
        <h2>Status</h2>
        <div id="status">Carregando...</div>
        <p id="statusMeta" class="small"></p>
        <div class="actions">
          <button onclick="action('/api/start')">Iniciar</button>
          <button onclick="action('/api/restart')">Reiniciar</button>
          <button class="danger" onclick="action('/api/stop')">Parar</button>
          <button class="gray" onclick="action('/api/clear-logs')">Limpar logs</button>
          <button class="gray" onclick="action('/api/archive-logs')">Arquivar logs</button>
          <a class="btn" href="http://SEU_IP:8188" target="_blank">Abrir ComfyUI</a>
        </div>
      </div>

      <div class="card">
        <h2>Sistema</h2>
        <div id="system" class="metric">Carregando...</div>
      </div>
    </div>

    <div class="grid-3" style="margin-top: 16px;">
      <div class="card">
        <h2>GPU</h2>
        <div id="gpu" class="metric">Carregando...</div>
      </div>
      <div class="card">
        <h2>Disco</h2>
        <div id="disk" class="metric">Carregando...</div>
      </div>
      <div class="card">
        <h2>Processo Comfy</h2>
        <div id="process" class="metric">Carregando...</div>
      </div>
    </div>

    <div class="grid" style="margin-top: 16px;">
      <div class="card">
        <h2>Log ativo</h2>
        <pre id="logActive"></pre>
      </div>
      <div class="card">
        <h2>Log de erro</h2>
        <pre id="logError"></pre>
      </div>
    </div>

    <div class="card" style="margin-top: 16px;">
      <h2>Histórico de logs</h2>
      <ul id="history"></ul>
    </div>
  </div>

  <script>
    const token = new URLSearchParams(window.location.search).get("token");

    async function fetchJson(url, options = {}) {
      const sep = url.includes("?") ? "&" : "?";
      const finalUrl = url + sep + "token=" + encodeURIComponent(token);
      const res = await fetch(finalUrl, options);
      if (!res.ok) throw new Error(await res.text());
      return await res.json();
    }

    async function action(url) {
      try {
        const data = await fetchJson(url, { method: "POST" });
        alert(data.message || "ok");
        await loadAll();
      } catch (err) {
        alert("Erro: " + err.message);
      }
    }

    async function loadStatus() {
      const data = await fetchJson("/api/status");
      document.getElementById("status").innerHTML = data.active
        ? '<span class="badge online">ONLINE</span>'
        : '<span class="badge offline">OFFLINE</span>';

      document.getElementById("statusMeta").innerText =
        "Uptime: " + (data.uptime || "-") +
        " | Porta 8188: " + (data.portOpen ? "respondendo" : "sem resposta");
    }

    async function loadSystem() {
      const data = await fetchJson("/api/system");
      document.getElementById("system").innerHTML =
        "Host: " + data.hostname + "<br>" +
        "Load avg: " + data.loadavg + "<br>" +
        "RAM usada: " + data.memUsedGb + " GB / " + data.memTotalGb + " GB<br>" +
        "RAM livre: " + data.memFreeGb + " GB";
    }

    async function loadGpu() {
      const data = await fetchJson("/api/gpu");
      document.getElementById("gpu").innerHTML =
        "GPU: " + data.name + "<br>" +
        "Uso: " + data.util + "%<br>" +
        "VRAM: " + data.memUsed + " MiB / " + data.memTotal + " MiB<br>" +
        "Temp: " + data.temp + " °C<br>" +
        "Fan: " + data.fan + "%<br>" +
        "Power: " + data.power + " W";
    }

    async function loadDisk() {
      const data = await fetchJson("/api/disk");
      document.getElementById("disk").innerHTML =
        "Partição: " + data.mount + "<br>" +
        "Usado: " + data.used + "<br>" +
        "Livre: " + data.available + "<br>" +
        "Total: " + data.size + "<br>" +
        "Uso: " + data.usePercent;
    }

    async function loadProcess() {
      const data = await fetchJson("/api/process");
      document.getElementById("process").innerHTML =
        "PID principal: " + data.pid + "<br>" +
        "CPU: " + data.cpu + "%<br>" +
        "RAM: " + data.mem + "%<br>" +
        "Threads: " + data.threads;
    }

    async function loadLogs() {
      const [active, error] = await Promise.all([
        fetchJson("/api/logs/active"),
        fetchJson("/api/logs/error")
      ]);

      const activeEl = document.getElementById("logActive");
      const errorEl = document.getElementById("logError");

      const shouldScrollActive =
        activeEl.scrollTop + activeEl.clientHeight >= activeEl.scrollHeight - 20;
      const shouldScrollError =
        errorEl.scrollTop + errorEl.clientHeight >= errorEl.scrollHeight - 20;

      activeEl.textContent = active.content || "";
      errorEl.textContent = error.content || "";

      if (shouldScrollActive) activeEl.scrollTop = activeEl.scrollHeight;
      if (shouldScrollError) errorEl.scrollTop = errorEl.scrollHeight;
    }

    async function loadHistory() {
      const data = await fetchJson("/api/logs/history");
      const ul = document.getElementById("history");
      ul.innerHTML = "";

      if (!data.files.length) {
        ul.innerHTML = "<li>Nenhum log arquivado ainda</li>";
        return;
      }

      for (const file of data.files) {
        const li = document.createElement("li");
        li.innerHTML =
          '<a class="loglink" target="_blank" href="/api/logs/file/' +
          encodeURIComponent(file) +
          '?token=' + encodeURIComponent(token) +
          '">' + file + '</a>';
        ul.appendChild(li);
      }
    }

    async function loadAll() {
      await Promise.all([
        loadStatus(),
        loadSystem(),
        loadGpu(),
        loadDisk(),
        loadProcess(),
        loadLogs(),
        loadHistory()
      ]);
    }

    loadAll();
    setInterval(loadStatus, 2000);
    setInterval(loadSystem, 5000);
    setInterval(loadGpu, 2500);
    setInterval(loadDisk, 10000);
    setInterval(loadProcess, 2500);
    setInterval(loadLogs, 1000);
    setInterval(loadHistory, 15000);
  </script>
</body>
</html>
  `);
});

app.get("/api/status", auth, async (req, res) => {
  const status = await run("systemctl is-active comfyui");
  const uptime = await run(
    "systemctl show comfyui -p ActiveEnterTimestamp --value",
  );
  const port = await run(
    "bash -lc 'ss -ltn | grep :8188 >/dev/null && echo open || echo closed'",
  );
  res.json({
    active: status.stdout === "active",
    uptime: uptime.stdout || "-",
    portOpen: port.stdout === "open",
  });
});

app.get("/api/system", auth, async (req, res) => {
  const total = os.totalmem() / 1024 / 1024 / 1024;
  const free = os.freemem() / 1024 / 1024 / 1024;
  const used = total - free;

  res.json({
    hostname: os.hostname(),
    loadavg: os
      .loadavg()
      .map((v) => v.toFixed(2))
      .join(" / "),
    memTotalGb: total.toFixed(2),
    memFreeGb: free.toFixed(2),
    memUsedGb: used.toFixed(2),
  });
});

app.get("/api/gpu", auth, async (req, res) => {
  const cmd = `nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,fan.speed,power.draw --format=csv,noheader,nounits`;
  const r = await run(cmd);

  if (!r.ok || !r.stdout) {
    return res.json({
      name: "N/A",
      util: "N/A",
      memUsed: "N/A",
      memTotal: "N/A",
      temp: "N/A",
      fan: "N/A",
      power: "N/A",
    });
  }

  const parts = r.stdout.split(",").map((s) => s.trim());

  res.json({
    name: parts[0] || "N/A",
    util: parts[1] || "N/A",
    memUsed: parts[2] || "N/A",
    memTotal: parts[3] || "N/A",
    temp: parts[4] || "N/A",
    fan: parts[5] || "N/A",
    power: parts[6] || "N/A",
  });
});

app.get("/api/disk", auth, async (req, res) => {
  const r = await run(
    `df -h / | awk 'NR==2 {print $6 "|" $3 "|" $4 "|" $2 "|" $5}'`,
  );
  const parts = r.stdout.split("|");

  res.json({
    mount: parts[0] || "/",
    used: parts[1] || "-",
    available: parts[2] || "-",
    size: parts[3] || "-",
    usePercent: parts[4] || "-",
  });
});

app.get("/api/process", auth, async (req, res) => {
  const pidResult = await run(`systemctl show comfyui -p MainPID --value`);
  const pid = pidResult.stdout || "0";

  if (!pid || pid === "0") {
    return res.json({
      pid: "-",
      cpu: "-",
      mem: "-",
      threads: "-",
    });
  }

  const r = await run(`ps -p ${pid} -o %cpu=,%mem=,nlwp=`);
  const parts = r.stdout.split(/\s+/).filter(Boolean);

  res.json({
    pid,
    cpu: parts[0] || "-",
    mem: parts[1] || "-",
    threads: parts[2] || "-",
  });
});

app.get("/api/logs/active", auth, async (req, res) => {
  res.json({ content: tailFile(LOG_FILE) });
});

app.get("/api/logs/error", auth, async (req, res) => {
  res.json({ content: tailFile(ERROR_LOG_FILE) });
});

app.get("/api/logs/history", auth, async (req, res) => {
  ensureArchiveDir();
  const files = fs
    .readdirSync(LOG_ARCHIVE_DIR)
    .filter((f) => f.endsWith(".log"))
    .sort()
    .reverse();

  res.json({ files });
});

app.get("/api/logs/file/:name", auth, async (req, res) => {
  const safeName = path.basename(req.params.name);
  const target = path.join(LOG_ARCHIVE_DIR, safeName);

  if (!fs.existsSync(target)) {
    return res.status(404).send("arquivo não encontrado");
  }

  res.type("text/plain");
  res.send(fs.readFileSync(target, "utf8"));
});

app.post("/api/start", auth, async (req, res) => {
  const r = await run("sudo systemctl start comfyui");
  res.json({
    ok: r.ok,
    message: r.ok ? "Comfy iniciado" : r.stderr || "erro ao iniciar",
  });
});

app.post("/api/stop", auth, async (req, res) => {
  const r = await run("sudo systemctl stop comfyui");
  res.json({
    ok: r.ok,
    message: r.ok ? "Comfy parado" : r.stderr || "erro ao parar",
  });
});

app.post("/api/restart", auth, async (req, res) => {
  const r = await run("sudo systemctl restart comfyui");
  res.json({
    ok: r.ok,
    message: r.ok ? "Comfy reiniciado" : r.stderr || "erro ao reiniciar",
  });
});

app.post("/api/clear-logs", auth, async (req, res) => {
  try {
    fs.writeFileSync(LOG_FILE, "");
    fs.writeFileSync(ERROR_LOG_FILE, "");
    res.json({ ok: true, message: "Logs limpos" });
  } catch (e) {
    res.json({ ok: false, message: "Erro ao limpar logs: " + e.message });
  }
});

app.post("/api/archive-logs", auth, async (req, res) => {
  try {
    ensureArchiveDir();
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");

    if (fs.existsSync(LOG_FILE) && fs.statSync(LOG_FILE).size > 0) {
      fs.copyFileSync(
        LOG_FILE,
        path.join(LOG_ARCHIVE_DIR, `comfyui-${stamp}.log`),
      );
      fs.writeFileSync(LOG_FILE, "");
    }

    if (fs.existsSync(ERROR_LOG_FILE) && fs.statSync(ERROR_LOG_FILE).size > 0) {
      fs.copyFileSync(
        ERROR_LOG_FILE,
        path.join(LOG_ARCHIVE_DIR, `comfyui-error-${stamp}.log`),
      );
      fs.writeFileSync(ERROR_LOG_FILE, "");
    }

    res.json({ ok: true, message: "Logs arquivados" });
  } catch (e) {
    res.json({ ok: false, message: "Erro ao arquivar logs: " + e.message });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log("Painel rodando na porta " + PORT);
});
