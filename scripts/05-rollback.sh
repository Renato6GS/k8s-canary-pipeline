#!/bin/bash
set -e

# ═══════════════════════════════════════════════════
#  PASO 5: Rollback — Eliminar Canary
# ═══════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

CANARY_NS="canary-demo"

echo -e "${RED}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  ⏪ ROLLBACK — Eliminando canary v2.0.0  ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Estado antes del rollback
echo -e "${YELLOW}[ANTES] Pods en ejecución:${NC}"
kubectl get pods -n "$CANARY_NS" --no-headers | awk '{print "  " $1 " → " $3}'
echo ""

# Eliminar deployment canary
echo -e "${YELLOW}[1/2]${NC} Eliminando deployment canary..."
kubectl delete deployment canary-demo-canary -n "$CANARY_NS" --ignore-not-found=true
echo -e "${GREEN}✓ Deployment canary eliminado.${NC}"

# Esperar a que los pods terminen
echo -e "${YELLOW}[2/2]${NC} Esperando que los pods canary se terminen..."
kubectl wait --for=delete pod -l track=canary -n "$CANARY_NS" --timeout=60s 2>/dev/null || true
sleep 2

echo ""

# Estado después del rollback
echo -e "${CYAN}[DESPUÉS] Pods en ejecución:${NC}"
kubectl get pods -n "$CANARY_NS" --no-headers | awk '{print "  " $1 " → " $3}'
echo ""

echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Rollback completado${NC}"
echo -e "${GREEN}    Todo el tráfico va ahora a stable v1.0.0${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo ""

# Verificación final
STABLE_PODS=$(kubectl get pods -n "$CANARY_NS" -l track=stable --no-headers | wc -l)
CANARY_PODS=$(kubectl get pods -n "$CANARY_NS" -l track=canary --no-headers | wc -l)

echo -e "  Pods stable: ${GREEN}${STABLE_PODS}${NC}"
echo -e "  Pods canary: ${GREEN}${CANARY_PODS}${NC} (debería ser 0)"
