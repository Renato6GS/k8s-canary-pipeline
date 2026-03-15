const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Configuración por variables de entorno ──────────────────
const APP_VERSION = process.env.APP_VERSION || '1.0.0';
const APP_TYPE    = process.env.APP_TYPE    || 'stable';  // "stable" | "canary"
const FAIL_AFTER  = parseInt(process.env.FAIL_AFTER || '0', 10); // 0 = nunca falla

// ── Estado interno ──────────────────────────────────────────
const startTime = Date.now();
let requestCount = 0;
let healthCheckCount = 0;

// ── Archivos estáticos ──────────────────────────────────────
app.use(express.static(path.join(__dirname, 'public')));

// ── API: Estado general ─────────────────────────────────────
app.get('/api/status', (req, res) => {
  requestCount++;
  res.json({
    version: APP_VERSION,
    type: APP_TYPE,
    hostname: os.hostname(),
    uptime: (Date.now() - startTime) / 1000,
    requestCount,
  });
});

// ── API: Health check ───────────────────────────────────────
//    Si FAIL_AFTER > 0, el endpoint empieza a fallar
//    después de esa cantidad de health checks (simula bug).
app.get('/api/health', (req, res) => {
  healthCheckCount++;

  const shouldFail = FAIL_AFTER > 0 && healthCheckCount > FAIL_AFTER;

  if (shouldFail) {
    console.error(`[HEALTH] FAIL — check #${healthCheckCount} (falla después de ${FAIL_AFTER})`);
    return res.status(500).json({
      status: 'unhealthy',
      error: `Crash simulado: memory leak detectado en v${APP_VERSION}`,
      checks: healthCheckCount,
    });
  }

  res.json({
    status: 'healthy',
    version: APP_VERSION,
    checks: healthCheckCount,
  });
});

// ── API: Readiness (para Kubernetes) ────────────────────────
app.get('/ready', (req, res) => {
  res.status(200).send('OK');
});

// ── Inicio ──────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════╗
║  🚀 Canary Demo Server                  ║
║  Version : ${APP_VERSION.padEnd(29)}║
║  Type    : ${APP_TYPE.padEnd(29)}║
║  Port    : ${String(PORT).padEnd(29)}║
║  Fail    : ${(FAIL_AFTER > 0 ? `después de ${FAIL_AFTER} checks` : 'nunca').padEnd(29)}║
╚══════════════════════════════════════════╝
  `);
});
