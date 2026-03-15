const $ = (sel) => document.querySelector(sel);

const elVersion     = $('#version');
const elTag         = $('#version-tag');
const elHealthDot   = $('#health-indicator');
const elHealthText  = $('#health-status');
const elHostname    = $('#hostname');
const elUptime      = $('#uptime');
const elRequests    = $('#requests');
const elLog         = $('#log');

function timeStr() {
  return new Date().toLocaleTimeString('es-GT', { hour12: false });
}

function addLog(msg, type = 'ok') {
  const entry = document.createElement('div');
  entry.className = 'entry';
  entry.innerHTML = `<span class="time">${timeStr()}</span><span class="${type}">${msg}</span>`;
  elLog.prepend(entry);

  // Mantener máximo 50 líneas
  while (elLog.children.length > 50) {
    elLog.removeChild(elLog.lastChild);
  }
}

function formatUptime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}m ${s}s`;
}

async function fetchStatus() {
  try {
    const res = await fetch('/api/status');
    const data = await res.json();

    // Versión
    elVersion.textContent = data.version;
    elTag.textContent = data.type;
    elTag.className = `tag ${data.type}`;

    // Info
    elHostname.textContent = data.hostname;
    elUptime.textContent = formatUptime(data.uptime);
    elRequests.textContent = data.requestCount;

    addLog(`GET /api/status → 200 (${data.type} ${data.version})`, 'ok');
  } catch (err) {
    addLog(`Error al conectar con el servidor`, 'err');
  }
}

async function fetchHealth() {
  try {
    const res = await fetch('/api/health');
    const data = await res.json();

    if (data.status === 'healthy') {
      elHealthDot.className = 'health-dot healthy';
      elHealthText.textContent = 'Saludable';
      elHealthText.style.color = 'var(--green)';
      addLog(`Health check: OK`, 'ok');
    } else {
      elHealthDot.className = 'health-dot unhealthy';
      elHealthText.textContent = 'Fallo detectado';
      elHealthText.style.color = 'var(--red)';
      addLog(`Health check: FALLO — ${data.error || 'servicio degradado'}`, 'err');
    }
  } catch (err) {
    elHealthDot.className = 'health-dot unhealthy';
    elHealthText.textContent = 'Sin conexión';
    elHealthText.style.color = 'var(--red)';
    addLog(`Health check: ERROR de red`, 'err');
  }
}

// Polling cada 3 segundos
async function poll() {
  await fetchStatus();
  await fetchHealth();
}

poll();
setInterval(poll, 3000);

addLog('Dashboard iniciado — esperando datos...', 'warn');
