#!/bin/bash

# ═══════════════════════════════════════════════════
#  PASO 4: Health Check — Monitoreo del Canary
# ═══════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

MAX_CHECKS=${1:-20}        # Número máximo de checks
INTERVAL=${2:-5}           # Segundos entre checks
FAIL_THRESHOLD=3           # Fallos consecutivos para rollback
CANARY_NS="canary-demo"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  🔍 HEALTH CHECK — MONITOREO CANARY     ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Checks: ${MAX_CHECKS} | Intervalo: ${INTERVAL}s | Umbral fallo: ${FAIL_THRESHOLD}"
echo ""

consecutive_fails=0
check_num=0

# Obtener IP del pod canary
get_canary_pod() {
  kubectl get pods -n "$CANARY_NS" -l track=canary -o jsonpath='{.items[0].metadata.name}' 2>/dev/null
}

for ((i = 1; i <= MAX_CHECKS; i++)); do
  check_num=$i
  CANARY_POD=$(get_canary_pod)

  if [ -z "$CANARY_POD" ]; then
    echo -e "  ${RED}[Check $i/$MAX_CHECKS] No se encontró pod canary.${NC}"
    consecutive_fails=$((consecutive_fails + 1))
  else
    # Ejecutar health check directamente en el pod
    HTTP_CODE=$(kubectl exec "$CANARY_POD" -n "$CANARY_NS" -- \
      wget -q -O - --server-response http://localhost:3000/api/health 2>&1 | \
      head -1 || echo "000")

    # Alternativa: usar port-forward con curl
    HEALTH_RESPONSE=$(kubectl exec "$CANARY_POD" -n "$CANARY_NS" -- \
      wget -q -O - http://localhost:3000/api/health 2>/dev/null || echo '{"status":"error"}')

    STATUS=$(echo "$HEALTH_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    if [ "$STATUS" = "healthy" ]; then
      echo -e "  ${GREEN}[Check $i/$MAX_CHECKS] ✓ Pod ${CANARY_POD} → healthy${NC}"
      consecutive_fails=0
    else
      consecutive_fails=$((consecutive_fails + 1))
      ERROR=$(echo "$HEALTH_RESPONSE" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
      echo -e "  ${RED}[Check $i/$MAX_CHECKS] ✗ Pod ${CANARY_POD} → FALLO ($consecutive_fails/$FAIL_THRESHOLD)${NC}"
      echo -e "    ${RED}  Detalle: ${ERROR:-respuesta no válida}${NC}"
    fi
  fi

  # ¿Umbral de fallos alcanzado?
  if [ "$consecutive_fails" -ge "$FAIL_THRESHOLD" ]; then
    echo ""
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║  ⚠  UMBRAL DE FALLOS ALCANZADO          ║${NC}"
    echo -e "${RED}${BOLD}║  Fallos consecutivos: ${consecutive_fails}/${FAIL_THRESHOLD}               ║${NC}"
    echo -e "${RED}${BOLD}║  → Iniciando ROLLBACK automático...      ║${NC}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # Ejecutar rollback
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    bash "$SCRIPT_DIR/05-rollback.sh"
    exit 1
  fi

  # Esperar antes del siguiente check
  if [ "$i" -lt "$MAX_CHECKS" ]; then
    sleep "$INTERVAL"
  fi
done

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Canary pasó todos los health checks (${MAX_CHECKS}/${MAX_CHECKS})${NC}"
echo -e "${GREEN}  → Listo para promover a producción.${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
