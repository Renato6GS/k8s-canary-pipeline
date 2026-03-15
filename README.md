# ⎈ Pipeline CD con Canary Deployment y Rollback en Kubernetes

Luis Renato Granados Ogaldez
2392-19-4642
> Pipeline de Continuous Deployment con estrategia Canary y rollback automático ante falla.

---

## Tabla de Contenidos

- [Descripción del Proyecto](#descripción-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Instalación y Setup](#instalación-y-setup)
- [1. Pipeline CD (Continuous Deployment)](#1-pipeline-cd-continuous-deployment)
- [2. Canary Releases](#2-canary-releases)
- [3. Rollback ante Falla](#3-rollback-ante-falla)
- [Ejecución Completa del Pipeline](#ejecución-completa-del-pipeline)
- [Ejecución Paso a Paso](#ejecución-paso-a-paso)
- [Verificación y Pruebas](#verificación-y-pruebas)
- [Limpieza](#limpieza)
- [Diagrama de Arquitectura](#diagrama-de-arquitectura)

---

## Descripción del Proyecto

Este proyecto demuestra un flujo completo de **Continuous Deployment (CD)** usando Kubernetes local con Minikube. Incluye:

- Una **aplicación web** (HTML, CSS, JS y Node.js) que sirve como dashboard de estado.
- **Dos versiones** de la app: `v1.0.0` (estable) y `v2.0.0` (con bug simulado).
- **Manifiestos de Kubernetes** para deployments, services y estrategia canary.
- **Scripts automatizados** que simulan cada etapa del pipeline CD.

La versión `v2.0.0` está diseñada para **fallar intencionalmente** después de 5 health checks, lo que permite demostrar el rollback automático.

---

## Requisitos Previos

| Herramienta | Descripción | Instalación |
|---|---|---|
| **Docker** | Motor de contenedores | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| **Minikube** | Clúster K8s local | Se instala automáticamente con `01-setup.sh` |
| **kubectl** | CLI de Kubernetes | Se instala automáticamente con `01-setup.sh` |

> **NOTA:** Solo necesitás tener Docker instalado y corriendo. El script de setup se encarga del resto.

### Verificar Docker

```bash
docker --version
# Docker version 24.x.x o superior

docker info
# Debe mostrar que el daemon está corriendo
```

---

## Estructura del Proyecto

```
k8s-canary-pipeline/
│
├── app/                        # Aplicación web
│   ├── public/
│   │   ├── index.html          # Dashboard principal
│   │   ├── styles.css          # Estilos del dashboard
│   │   └── app.js              # Lógica del frontend (polling)
│   ├── server.js               # Servidor Express (API + static)
│   ├── package.json            # Dependencias Node.js
│   └── Dockerfile              # Imagen Docker de la app
│
├── k8s/                        # Manifiestos de Kubernetes
│   ├── namespace.yaml          # Namespace: canary-demo
│   ├── deployment-stable.yaml  # Deployment v1 (4 réplicas)
│   ├── deployment-canary.yaml  # Deployment v2 (1 réplica, con bug)
│   └── service.yaml            # Service NodePort (puerto 30080)
│
├── scripts/                    # Scripts individuales
│   ├── 01-setup.sh             # Instalar herramientas + construir imágenes
│   ├── 02-deploy-stable.sh     # Desplegar versión estable
│   ├── 03-canary-deploy.sh     # Desplegar canary junto a stable
│   ├── 04-health-check.sh      # Monitorear canary + rollback automático
│   ├── 05-rollback.sh          # Rollback manual (eliminar canary)
│   └── cleanup.sh              # Limpiar todos los recursos
│
├── pipeline/
│   └── cd-pipeline.sh          # Pipeline completo automatizado
│
└── README.md                   # Este archivo
```

---

## Instalación y Setup

### 1. Clonar o copiar el proyecto

```bash
cd k8s-canary-pipeline
```

### 2. Dar permisos de ejecución a todos los scripts

```bash
chmod +x scripts/*.sh pipeline/*.sh
```

### 3. Ejecutar el setup

```bash
bash scripts/01-setup.sh
```

Este script:
- Verifica que Docker esté corriendo.
- Instala `kubectl` si no está presente.
- Instala `Minikube` si no está presente.
- Inicia un clúster Kubernetes local.
- Construye las imágenes Docker `canary-demo:v1` y `canary-demo:v2` dentro de Minikube.

---

## 1. Pipeline CD (Continuous Deployment)

### ¿Qué es un Pipeline CD?

Un pipeline de **Continuous Deployment** automatiza el proceso de llevar código desde un repositorio hasta producción. En este proyecto, el pipeline consta de estas etapas:

```
 ┌──────────┐    ┌──────────────┐    ┌────────────────┐    ┌──────────────┐    ┌──────────┐
 │  BUILD   │ →  │ DEPLOY v1    │ →  │ CANARY DEPLOY  │ →  │ HEALTH CHECK │ →  │ DECISIÓN │
 │ (Docker) │    │ (Stable)     │    │ (v2 parcial)   │    │ (Monitoreo)  │    │ ✓ o ✗    │
 └──────────┘    └──────────────┘    └────────────────┘    └──────────────┘    └──────────┘
                                                                                   │
                                                                    ┌──────────────┤
                                                                    │              │
                                                              ✓ Promover     ✗ Rollback
                                                              canary a       a versión
                                                              producción     estable
```

### Etapas del Pipeline

| Etapa | Script | Qué hace |
|---|---|---|
| **Build** | `01-setup.sh` | Construye imágenes Docker v1 y v2 |
| **Deploy Stable** | `02-deploy-stable.sh` | Despliega v1.0.0 con 4 réplicas |
| **Canary Deploy** | `03-canary-deploy.sh` | Agrega v2.0.0 con 1 réplica |
| **Health Check** | `04-health-check.sh` | Monitorea el canary cada 5s |
| **Rollback** | `05-rollback.sh` | Elimina el canary si falla |

### Cómo funciona en este proyecto

El archivo `pipeline/cd-pipeline.sh` ejecuta todas las etapas **secuencialmente**, pausando entre cada una para que se pueda observar el resultado. Al final, muestra si el canary fue aprobado o rechazado.

---

## 2. Canary Releases

### ¿Qué es un Canary Release?

Un **canary release** es una estrategia de despliegue donde una nueva versión se despliega a un **subconjunto pequeño de usuarios** antes de reemplazar la versión anterior por completo. El nombre viene de los canarios que se usaban en minas de carbón como sistema de alerta temprana.

### Cómo se implementa en Kubernetes

La clave está en el **Service** y los **labels**:

```yaml
# El Service selecciona por "app: canary-demo" (sin track)
# Así, AMBOS deployments reciben tráfico:

Service (canary-demo-svc)
  selector: app=canary-demo     ← coincide con ambos
       │
       ├── Deployment stable    ← labels: app=canary-demo, track=stable
       │   (4 réplicas)            80% del tráfico (4/5 pods)
       │
       └── Deployment canary    ← labels: app=canary-demo, track=canary
           (1 réplica)             20% del tráfico (1/5 pods)
```

### Distribución de tráfico

Con 4 pods stable y 1 pod canary, Kubernetes distribuye el tráfico de forma **round-robin** entre los 5 pods:

| Pod | Versión | Track | Tráfico aprox. |
|---|---|---|---|
| stable-pod-1 | v1.0.0 | stable | ~20% |
| stable-pod-2 | v1.0.0 | stable | ~20% |
| stable-pod-3 | v1.0.0 | stable | ~20% |
| stable-pod-4 | v1.0.0 | stable | ~20% |
| canary-pod-1 | v2.0.0 | canary | ~20% |

### Verificar el canary en acción

Después de desplegar el canary, podés verificar que el tráfico se divide entre ambas versiones:

```bash
# Hacer múltiples requests y ver qué versión responde
for i in $(seq 1 10); do
  curl -s http://$(minikube ip):30080/api/status | grep -o '"version":"[^"]*"'
done
```

Deberías ver que ~80% de las respuestas son `v1.0.0` y ~20% son `v2.0.0`.

---

## 3. Rollback ante Falla

### ¿Qué es un Rollback?

Un **rollback** es el proceso de revertir un despliegue a una versión anterior cuando se detecta un problema. En el contexto de canary releases, el rollback consiste en **eliminar el deployment canary** para que todo el tráfico vuelva a la versión estable.

### Cómo se simula la falla

La versión `v2.0.0` tiene un **bug intencional**: su endpoint `/api/health` empieza a devolver errores HTTP 500 después de 5 health checks. Esto simula un escenario real donde una nueva versión tiene un memory leak u otro problema que solo se manifiesta después de un tiempo.

```javascript
// En server.js, la v2 está configurada con:
FAIL_AFTER=5   // Después del 5to health check, responde con 500

// El health check detecta:
// Check 1-5:  200 OK     ← "todo bien"
// Check 6+:   500 ERROR  ← "memory leak detectado"
```

### Flujo del rollback automático

```
Health Check Loop:
  ┌─────────────────────────────────────┐
  │ Check 1: ✓ healthy                  │
  │ Check 2: ✓ healthy                  │
  │ Check 3: ✓ healthy                  │
  │ Check 4: ✓ healthy                  │
  │ Check 5: ✓ healthy                  │  ← Último check exitoso
  │ Check 6: ✗ FALLO (1/3)             │  ← Bug se manifiesta
  │ Check 7: ✗ FALLO (2/3)             │
  │ Check 8: ✗ FALLO (3/3)             │  ← Umbral alcanzado
  │                                     │
  │ ⚠ ROLLBACK AUTOMÁTICO ACTIVADO     │
  │ → kubectl delete deployment canary  │
  │ → Tráfico: 100% a v1.0.0           │
  └─────────────────────────────────────┘
```

### Rollback manual

Si preferís ejecutar el rollback manualmente:

```bash
bash scripts/05-rollback.sh
```

O directamente con kubectl:

```bash
kubectl delete deployment canary-demo-canary -n canary-demo
```

---

## Ejecución Completa del Pipeline

Para ejecutar **todo el pipeline de una vez** (recomendado para la demostración):

```bash
bash pipeline/cd-pipeline.sh
```

El pipeline se pausa entre cada etapa. Presiona **ENTER** para avanzar. Al llegar a la etapa de health check, verás cómo el canary pasa los primeros checks y luego empieza a fallar, activando el rollback automático.

---

## Ejecución Paso a Paso

Si preferís ejecutar cada etapa manualmente:

```bash
# 1. Setup del entorno (instalar herramientas + construir imágenes)
bash scripts/01-setup.sh

# 2. Desplegar versión estable
bash scripts/02-deploy-stable.sh

# 3. Abrir la app en el navegador (opcional)
minikube service canary-demo-svc -n canary-demo

# 4. Desplegar canary
bash scripts/03-canary-deploy.sh

# 5. Monitorear canary (activará rollback automáticamente)
bash scripts/04-health-check.sh

# 6. (Alternativa) Rollback manual
bash scripts/05-rollback.sh
```

---

## Verificación y Pruebas

### Ver pods en ejecución

```bash
kubectl get pods -n canary-demo -o wide
```

### Ver logs de un pod

```bash
# Pod stable
kubectl logs -l track=stable -n canary-demo --tail=20

# Pod canary
kubectl logs -l track=canary -n canary-demo --tail=20
```

### Acceder al dashboard web

```bash
minikube service canary-demo-svc -n canary-demo
```

Esto abre el navegador con el dashboard. El dashboard muestra en tiempo real la versión del pod que responde, su estado de salud, hostname y un log de actividad.

### Probar distribución de tráfico

```bash
# 20 requests para ver la distribución
for i in $(seq 1 20); do
  curl -s http://$(minikube ip):30080/api/status | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d[\"type\"]:>8} {d[\"version\"]}')"
done
```

### Probar health check directamente

```bash
# Al pod canary
CANARY_POD=$(kubectl get pods -n canary-demo -l track=canary -o jsonpath='{.items[0].metadata.name}')
kubectl exec $CANARY_POD -n canary-demo -- wget -qO- http://localhost:3000/api/health
```

---

## Limpieza

Para eliminar todos los recursos creados:

```bash
bash scripts/cleanup.sh
```

Para detener o eliminar Minikube:

```bash
minikube stop      # Detener el clúster (se puede reiniciar)
minikube delete    # Eliminar el clúster completamente
```

---

## Diagrama de Arquitectura

```
                        ┌─────────────────────────────────────────────────┐
                        │              Clúster Kubernetes (Minikube)       │
                        │                                                 │
  Usuario/Browser       │    ┌──────────────────────────────────────┐     │
       │                │    │  Service: canary-demo-svc            │     │
       │  :30080        │    │  selector: app=canary-demo           │     │
       └───────────────►│    │  NodePort: 30080 → targetPort: 3000  │     │
                        │    └────────────────┬─────────────────────┘     │
                        │                     │                           │
                        │         ┌───────────┴───────────┐               │
                        │         │                       │               │
                        │         ▼                       ▼               │
                        │  ┌─────────────┐         ┌─────────────┐       │
                        │  │  Deployment │         │  Deployment │       │
                        │  │  stable     │         │  canary     │       │
                        │  │  v1.0.0     │         │  v2.0.0     │       │
                        │  │  4 réplicas │         │  1 réplica  │       │
                        │  │  ✓ healthy  │         │  ✗ falla    │       │
                        │  └─────────────┘         └─────────────┘       │
                        │     80% tráfico            20% tráfico         │
                        │                                                 │
                        └─────────────────────────────────────────────────┘

  Pipeline CD:
  ┌────────┐   ┌──────────┐   ┌────────┐   ┌──────────────┐   ┌──────────┐
  │ Build  │ → │ Deploy   │ → │ Canary │ → │ Health Check │ → │ Rollback │
  │ Docker │   │ Stable   │   │ Deploy │   │ Monitoreo    │   │ (si ✗)   │
  └────────┘   └──────────┘   └────────┘   └──────────────┘   └──────────┘
```

---

## Tecnologías Utilizadas

| Tecnología | Uso |
|---|---|
| **HTML/CSS/JS** | Frontend del dashboard |
| **Node.js + Express** | Backend API |
| **Docker** | Contenedorización |
| **Kubernetes** | Orquestación de contenedores |
| **Minikube** | Clúster K8s local |
| **Bash** | Scripts de automatización del pipeline |

---

## Autor

Proyecto creado como práctica del curso de **Administración de Websites**.
