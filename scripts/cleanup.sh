#!/bin/bash

# ═══════════════════════════════════════════════════
#  LIMPIEZA — Eliminar todos los recursos
# ═══════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  🧹 LIMPIEZA COMPLETA                   ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Eliminando namespace (y todos sus recursos)...${NC}"
kubectl delete namespace canary-demo --ignore-not-found=true

echo -e "${YELLOW}Eliminando imágenes Docker del clúster...${NC}"
eval $(minikube docker-env 2>/dev/null)
docker rmi canary-demo:v1 canary-demo:v2 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Limpieza completa.${NC}"
echo -e "  Para detener Minikube: ${CYAN}minikube stop${NC}"
echo -e "  Para eliminarlo:       ${CYAN}minikube delete${NC}"
