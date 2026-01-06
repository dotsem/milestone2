# SVB Webstack - Kubernetes Milestone 2

A 3-tier web application stack deployed on Kubernetes using kind.

## 📁 Project Structure

```
milestone2/
├── backend/                 # FastAPI Backend
│   ├── main.py             # API endpoints (/api/user, /api/id, /api/health)
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Backend container build
├── frontend/               # Nginx Frontend
│   ├── index.html          # Web page (fetches from API)
│   ├── nginx.conf          # Nginx config with API proxy
│   └── Dockerfile          # Frontend container build
├── k8s/                    # Kubernetes Manifests
│   ├── namespace.yaml      # Namespace isolation
│   ├── secrets.yaml        # Database credentials
│   ├── configmap.yaml      # Backend config + Nginx config
│   ├── database.yaml       # PostgreSQL StatefulSet + PVC + Service
│   ├── backend.yaml        # FastAPI Deployment + Service
│   ├── frontend.yaml       # Nginx Deployment + NodePort Service
│   └── ingress.yaml        # Ingress routing rules
├── docker-compose.yml      # Docker-only deployment (5 points)
├── kind-config.yaml        # Kind cluster with 2 workers
├── deploy.sh               # Automated deployment script
├── cleanup.sh              # Cleanup script
└── README.md               # This file
```

## 🚀 Quick Start

### Option 1: Docker Compose (5 points)

```bash
# Build and start all services
docker-compose up --build -d

# Access the application
open http://localhost:8080

# View logs
docker-compose logs -f

# Stop and cleanup
docker-compose down -v
```

### Option 2: Kubernetes with Kind (10+ points)

```bash
# Run the automated deployment script
./deploy.sh

# Access the application
open http://localhost      # Via Ingress
open http://localhost:30080 # Via NodePort

# Cleanup
./cleanup.sh       # Remove namespace only
./cleanup.sh --all # Delete entire cluster
```

## 🔍 Manual Kubernetes Deployment

If you prefer step-by-step commands:

```bash
# 1. Create the kind cluster
kind create cluster --config kind-config.yaml --name svb-cluster

# 2. Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 3. Wait for Ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 4. Build Docker images
docker build -t svb-backend:latest ./backend
docker build -t svb-frontend:latest ./frontend

# 5. Load images into kind
kind load docker-image svb-backend:latest --name svb-cluster
kind load docker-image svb-frontend:latest --name svb-cluster

# 6. Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/database.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress.yaml

# 7. Wait for pods
kubectl wait --namespace svb-webstack \
  --for=condition=ready pod --all \
  --timeout=120s

# 8. Check status
kubectl get all -n svb-webstack
```

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Kind Cluster                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Ingress Controller                      │  │
│  │                    (nginx-ingress)                         │  │
│  │                         │                                  │  │
│  │         ┌───────────────┴───────────────┐                  │  │
│  │         │                               │                  │  │
│  │    path: /                        path: /api               │  │
│  │         ▼                               ▼                  │  │
│  │  ┌─────────────┐              ┌─────────────────┐          │  │
│  │  │  Frontend   │              │     Backend     │          │  │
│  │  │   (Nginx)   │              │    (FastAPI)    │          │  │
│  │  │  1 replica  │              │   2 replicas    │          │  │
│  │  └─────────────┘              └────────┬────────┘          │  │
│  │                                        │                   │  │
│  │                                        ▼                   │  │
│  │                               ┌─────────────────┐          │  │
│  │                               │    Database     │          │  │
│  │                               │  (PostgreSQL)   │          │  │
│  │                               │  StatefulSet    │          │  │
│  │                               │    + PVC        │          │  │
│  │                               └─────────────────┘          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Control Plane│  │   Worker 1   │  │   Worker 2   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## 🧪 Testing

### Test API Endpoints

```bash
# Get user name from database
curl http://localhost/api/user

# Get container ID (shows load balancing)
curl http://localhost/api/id

# Health check
curl http://localhost/api/health

# Update user name
curl -X PUT http://localhost/api/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Your Name"}'
```

### Demonstrate Load Balancing

```bash
# Run multiple times to see different container IDs
for i in {1..10}; do curl -s http://localhost/api/id; echo; done
```

### Demonstrate Health Checks

```bash
# Delete a backend pod - it will restart automatically
kubectl delete pod -n svb-webstack -l app.kubernetes.io/component=backend --wait=false

# Watch pods restart
kubectl get pods -n svb-webstack -w
```

### Scale Backend

```bash
# Scale to 3 replicas
kubectl scale deployment svb-backend -n svb-webstack --replicas=3

# Verify pods across nodes
kubectl get pods -n svb-webstack -o wide
```

## 📋 Points Breakdown

| Requirement | Points | Status |
|------------|--------|--------|
| Stack in Docker | 5 | ✅ docker-compose.yml |
| Kind cluster with 1 worker | 10 | ✅ kind-config.yaml |
| Extra worker + scaling via Ingress | +1 | ✅ 2 workers configured |
| Health check auto-restart | +1 | ✅ Liveness/readiness probes |
| HTTPS with cert-manager | +2 | 📝 Template in ingress.yaml |
| Prometheus monitoring | +2 | ⬜ Not yet implemented |
| Kubeadm OR ArgoCD | +4 | ⬜ Not yet implemented |

## 📝 Documentation Notes

Every file contains detailed comments explaining:
- WHY each configuration choice was made
- WHAT each parameter does
- HOW it relates to the overall architecture

This follows the assignment requirement: "Document every step and command... Explain every parameter and option."
