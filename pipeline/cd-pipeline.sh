#!/bin/bash

# ═══════════════════════════════════════════════════════════════
#  PIPELINE CD COMPLETO
#  Simula: Build → Deploy Stable → Canary Release → Health
#          Check → Rollback automático ante falla
# ═══════════════════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$SCRIPT_DIR/../scripts"

clear

echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║                                                       ║"
echo "║     ⎈  PIPELINE DE CONTINUOUS DEPLOYMENT              ║"
echo "║        con Canary Release y Rollback Automático       ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

pause() {
  echo ""
  echo -e "${YELLOW}─── Presiona ENTER para continuar al siguiente paso... ───${NC}"
  read -r
  echo ""
}

# ── STAGE 1: Setup ──────────────────────────────────────
echo -e "${MAGENTA}━━━ STAGE 1/5: Setup del entorno ━━━${NC}"
bash "$SCRIPTS/01-setup.sh"
pause

# ── STAGE 2: Deploy Stable ──────────────────────────────
echo -e "${MAGENTA}━━━ STAGE 2/5: Deploy versión estable (v1.0.0) ━━━${NC}"
bash "$SCRIPTS/02-deploy-stable.sh"
pause

# ── STAGE 3: Canary Deploy ──────────────────────────────
echo -e "${MAGENTA}━━━ STAGE 3/5: Canary Deploy (v2.0.0) ━━━${NC}"
bash "$SCRIPTS/03-canary-deploy.sh"
pause

# ── STAGE 4: Health Check + Auto-Rollback ───────────────
echo -e "${MAGENTA}━━━ STAGE 4/5: Health Check (monitoreo continuo) ━━━${NC}"
echo -e "${YELLOW}El canary v2.0.0 está configurado para fallar después de 5 health checks.${NC}"
echo -e "${YELLOW}El sistema detectará la falla y ejecutará rollback automáticamente.${NC}"
echo ""

# Ejecutar health check (max 20 checks, cada 5 segundos)
bash "$SCRIPTS/04-health-check.sh" 20 5
HEALTH_EXIT=$?

echo ""

# ── STAGE 5: Resultado final ───────────────────────────
echo -e "${MAGENTA}━━━ STAGE 5/5: Resultado del Pipeline ━━━${NC}"
echo ""

if [ $HEALTH_EXIT -ne 0 ]; then
  echo -e "${RED}${BOLD}"
  echo "  ╔═════════════════════════════════════════╗"
  echo "  ║  Pipeline: CANARY RECHAZADO             ║"
  echo "  ║  v2.0.0 falló los health checks         ║"
  echo "  ║  Rollback ejecutado → v1.0.0 activa     ║"
  echo "  ╚═════════════════════════════════════════╝"
  echo -e "${NC}"
else
  echo -e "${GREEN}${BOLD}"
  echo "  ╔═════════════════════════════════════════╗"
  echo "  ║  Pipeline: CANARY APROBADO              ║"
  echo "  ║  v2.0.0 pasó todos los health checks    ║"
  echo "  ║  Listo para promover a producción       ║"
  echo "  ╚═════════════════════════════════════════╝"
  echo -e "${NC}"
fi

echo ""
echo -e "${CYAN}Estado final del clúster:${NC}"
kubectl get pods -n canary-demo -o wide 2>/dev/null || echo "  (namespace no encontrado)"
echo ""
echo -e "${MAGENTA}${BOLD}Pipeline completado.${NC}"
