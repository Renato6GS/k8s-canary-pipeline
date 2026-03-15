#!/bin/bash
set -e

# ═══════════════════════════════════════════════════
#  PASO 1: Setup del entorno
# ═══════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║  ⎈  SETUP DEL ENTORNO                   ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Verificar Docker ─────────────────────────────
echo -e "${YELLOW}[1/4]${NC} Verificando Docker..."
if ! command -v docker &> /dev/null; then
  echo -e "${RED}✗ Docker no está instalado. Por favor instálalo primero.${NC}"
  echo "  → https://docs.docker.com/get-docker/"
  exit 1
fi
echo -e "${GREEN}✓ Docker encontrado: $(docker --version)${NC}"

# ── Verificar/Instalar kubectl ───────────────────
echo -e "${YELLOW}[2/4]${NC} Verificando kubectl..."
if ! command -v kubectl &> /dev/null; then
  echo -e "${YELLOW}  Instalando kubectl...${NC}"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi
echo -e "${GREEN}✓ kubectl encontrado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"

# ── Verificar/Instalar Minikube ──────────────────
echo -e "${YELLOW}[3/4]${NC} Verificando Minikube..."
if ! command -v minikube &> /dev/null; then
  echo -e "${YELLOW}  Instalando Minikube...${NC}"
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  chmod +x minikube-linux-amd64
  sudo mv minikube-linux-amd64 /usr/local/bin/minikube

  # Si estás en macOS, usa en su lugar:
  # curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
  # chmod +x minikube-darwin-amd64
  # sudo mv minikube-darwin-amd64 /usr/local/bin/minikube
fi
echo -e "${GREEN}✓ Minikube encontrado: $(minikube version --short 2>/dev/null || minikube version)${NC}"

# ── Iniciar clúster ──────────────────────────────
echo -e "${YELLOW}[4/4]${NC} Iniciando clúster Minikube..."
if minikube status | grep -q "Running"; then
  echo -e "${GREEN}✓ Clúster ya está corriendo.${NC}"
else
  minikube start --driver=docker
  echo -e "${GREEN}✓ Clúster iniciado correctamente.${NC}"
fi

# ── Construir imágenes Docker dentro de Minikube ─
echo ""
echo -e "${CYAN}${BOLD}Construyendo imágenes Docker...${NC}"
echo -e "${YELLOW}  (Usando el Docker daemon de Minikube)${NC}"

eval $(minikube docker-env)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"

echo -e "${YELLOW}  → Construyendo canary-demo:v1 (stable)...${NC}"
docker build -t canary-demo:v1 \
  --build-arg APP_VERSION=1.0.0 \
  "$APP_DIR"

echo -e "${YELLOW}  → Construyendo canary-demo:v2 (canary con bug)...${NC}"
docker build -t canary-demo:v2 \
  --build-arg APP_VERSION=2.0.0 \
  "$APP_DIR"

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Setup completado exitosamente${NC}"
echo -e "${GREEN}    Imágenes: canary-demo:v1 y canary-demo:v2${NC}"
echo -e "${GREEN}    Clúster:  minikube (activo)${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
