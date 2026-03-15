#!/bin/bash
set -e

# ═══════════════════════════════════════════════════
#  PASO 3: Despliegue Canary (v2.0.0)
# ═══════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../k8s"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  🐤 CANARY DEPLOY (v2.0.0)              ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Estrategia canary:${NC}"
echo "  ┌─────────────────────────────────────────┐"
echo "  │  stable  v1.0.0  ████████████████  4 pods  (80% tráfico) │"
echo "  │  canary  v2.0.0  ████              1 pod   (20% tráfico) │"
echo "  └─────────────────────────────────────────┘"
echo ""

# Desplegar canary
echo -e "${YELLOW}[1/2]${NC} Desplegando canary v2.0.0..."
kubectl apply -f "$K8S_DIR/deployment-canary.yaml"
echo -e "${GREEN}✓ Deployment 'canary-demo-canary' aplicado.${NC}"

# Esperar a que esté listo
echo -e "${YELLOW}[2/2]${NC} Esperando que el pod canary esté listo..."
kubectl rollout status deployment/canary-demo-canary -n canary-demo --timeout=120s

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Canary desplegado junto a la versión estable${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo ""

# Mostrar distribución de pods
echo -e "${CYAN}Distribución actual de pods:${NC}"
echo ""
echo "  Stable (v1):"
kubectl get pods -n canary-demo -l track=stable --no-headers | awk '{print "    ● " $1 " → " $3}'
echo ""
echo "  Canary (v2):"
kubectl get pods -n canary-demo -l track=canary --no-headers | awk '{print "    ◆ " $1 " → " $3}'
echo ""

echo -e "${YELLOW}NOTA:${NC} El Service dirige tráfico a AMBOS deployments."
echo -e "      ~80% irá a stable (4 pods) y ~20% a canary (1 pod)."
echo ""
echo -e "${YELLOW}Siguiente paso:${NC} Ejecutar el health check para monitorear el canary."
echo -e "  → bash scripts/04-health-check.sh"
