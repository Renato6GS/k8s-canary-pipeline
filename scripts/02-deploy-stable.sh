#!/bin/bash
set -e

# ═══════════════════════════════════════════════════
#  PASO 2: Despliegue de la versión estable (v1)
# ═══════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../k8s"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  🚀 DEPLOY VERSIÓN ESTABLE (v1.0.0)     ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Crear namespace
echo -e "${YELLOW}[1/3]${NC} Creando namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"
echo -e "${GREEN}✓ Namespace 'canary-demo' creado.${NC}"

# Desplegar versión estable
echo -e "${YELLOW}[2/3]${NC} Desplegando v1.0.0 (4 réplicas)..."
kubectl apply -f "$K8S_DIR/deployment-stable.yaml"
echo -e "${GREEN}✓ Deployment 'canary-demo-stable' aplicado.${NC}"

# Crear servicio
echo -e "${YELLOW}[3/3]${NC} Exponiendo servicio..."
kubectl apply -f "$K8S_DIR/service.yaml"
echo -e "${GREEN}✓ Service 'canary-demo-svc' creado (NodePort 30080).${NC}"

# Esperar a que los pods estén listos
echo ""
echo -e "${YELLOW}Esperando a que los pods estén listos...${NC}"
kubectl rollout status deployment/canary-demo-stable -n canary-demo --timeout=120s

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Versión estable desplegada${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo ""

# Mostrar estado
echo -e "${CYAN}Estado actual:${NC}"
kubectl get pods -n canary-demo -o wide
echo ""
kubectl get svc -n canary-demo

echo ""
echo -e "${YELLOW}Para acceder a la app:${NC}"
echo -e "  minikube service canary-demo-svc -n canary-demo"
echo -e "  o bien: curl http://\$(minikube ip):30080"
