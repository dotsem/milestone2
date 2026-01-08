#!/bin/bash
# ==============================================================================
# SVB Webstack Deployment Script
# ==============================================================================
# This script automates the complete deployment of the webstack to a kind cluster.
#
# USAGE:
#   chmod +x deploy.sh
#   ./deploy.sh
#
# WHAT IT DOES:
# 1. Creates a kind cluster (if not exists)
# 2. Installs NGINX Ingress Controller
# 3. Builds and loads Docker images
# 4. Applies all Kubernetes manifests
# 5. Waits for pods to be ready
# 6. Displays access information

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cluster name (using your initials)
CLUSTER_NAME="svb-cluster"
NAMESPACE="svb-webstack"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SVB Webstack Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ==============================================================================
# STEP 1: Create Kind Cluster
# ==============================================================================
echo -e "${YELLOW}[Step 1/6] Checking kind cluster...${NC}"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${GREEN}✓ Cluster '${CLUSTER_NAME}' already exists${NC}"
else
    echo -e "${YELLOW}Creating kind cluster '${CLUSTER_NAME}'...${NC}"
    # WHY --config?
    # - Uses our custom configuration with extra workers and port mappings
    kind create cluster --config kind-config.yaml --name ${CLUSTER_NAME}
    echo -e "${GREEN}✓ Cluster created successfully${NC}"
fi

# Set kubectl context
# WHY?
# - Ensures we're working with the right cluster
kubectl cluster-info --context kind-${CLUSTER_NAME} > /dev/null 2>&1
echo -e "${GREEN}✓ kubectl context set to kind-${CLUSTER_NAME}${NC}"
echo ""

# ==============================================================================
# STEP 2: Install ArgoCD (GitOps)
# ==============================================================================
echo -e "${YELLOW}[Step 2/6] Installing ArgoCD...${NC}"

# Add Argo Helm repo
echo -e "${BLUE}Adding Argo Helm repository...${NC}"
helm repo add argo https://argoproj.github.io/argo-helm > /dev/null 2>&1
helm repo update > /dev/null 2>&1

# Install ArgoCD via Helm
if kubectl get deployment argocd-server -n argocd > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ArgoCD already installed${NC}"
else
    echo -e "${BLUE}Installing ArgoCD (this may take a minute)...${NC}"
    helm install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --set server.service.type=ClusterIP \
        --wait

    echo -e "${GREEN}✓ ArgoCD installation complete${NC}"
fi

# Wait for ArgoCD server
echo -e "${YELLOW}Waiting for ArgoCD server to be ready...${NC}"
kubectl wait --namespace argocd \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=argocd-server \
    --timeout=300s
echo -e "${GREEN}✓ ArgoCD server ready${NC}"
echo ""

# ==============================================================================
# STEP 3: Build Docker Images
# ==============================================================================
echo -e "${YELLOW}[Step 3/6] Building Docker images...${NC}"

# Build backend image
# WHY -t svb-backend:latest?
# - Tags the image with your initials as required
echo -e "${BLUE}Building svb-backend...${NC}"
docker build -t svb-backend:latest ./backend

# Build frontend image
echo -e "${BLUE}Building svb-frontend...${NC}"
docker build -t svb-frontend:latest ./frontend

echo -e "${GREEN}✓ Images built successfully${NC}"
echo ""

# ==============================================================================
# STEP 4: Load Images into Kind
# ==============================================================================
echo -e "${YELLOW}[Step 4/6] Loading images into kind cluster...${NC}"

# WHY kind load?
# - kind runs in Docker, so it can't access local Docker images directly
# - We need to load the images into the kind cluster's container runtime
kind load docker-image svb-backend:latest --name ${CLUSTER_NAME}
kind load docker-image svb-frontend:latest --name ${CLUSTER_NAME}

echo -e "${GREEN}✓ Images loaded into cluster${NC}"
echo ""

# ==============================================================================
# STEP 5: Apply ArgoCD Application
# ==============================================================================
echo -e "${YELLOW}[Step 5/6] Deploying via ArgoCD...${NC}"

# Ensure CRDs are applied (ArgoCD might have trouble with CRDs in the same sync initially or if they are large)
echo -e "${BLUE}Applying Traefik CRDs manually (best practice for CRDs)...${NC}"
kubectl apply -f k8s/traefik-crds.yaml

echo -e "${BLUE}Applying ArgoCD Application manifest...${NC}"
kubectl apply -f argocd/application.yaml

echo -e "${GREEN}✓ ArgoCD Application applied${NC}"
echo -e "${YELLOW}ArgoCD will now sync the repository instructions...${NC}"
echo ""

# ==============================================================================
# STEP 6: Wait for Pods to be Ready
# ==============================================================================
echo -e "${YELLOW}[Step 6/6] Waiting for pods to be ready...${NC}"

# Wait for database
echo -e "${BLUE}Waiting for database...${NC}"
kubectl wait --namespace ${NAMESPACE} \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=database \
    --timeout=120s

# Wait for backend
echo -e "${BLUE}Waiting for backend...${NC}"
kubectl wait --namespace ${NAMESPACE} \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=backend \
    --timeout=120s

# Wait for frontend
echo -e "${BLUE}Waiting for frontend...${NC}"
kubectl wait --namespace ${NAMESPACE} \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=frontend \
    --timeout=120s

echo -e "${GREEN}✓ All pods ready${NC}"
echo ""

# ==============================================================================
# DISPLAY STATUS
# ==============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}Pods:${NC}"
kubectl get pods -n ${NAMESPACE} -o wide

echo ""
echo -e "${GREEN}Services:${NC}"
kubectl get services -n ${NAMESPACE}

echo ""
echo -e "${GREEN}Ingress:${NC}"
kubectl get ingress -n ${NAMESPACE}

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Access Information${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Frontend (via Ingress):  ${GREEN}http://localhost/${NC}"
echo -e "Frontend (via NodePort): ${GREEN}http://localhost:30080/${NC}"
echo -e "API User endpoint:       ${GREEN}http://localhost/api/user${NC}"
echo -e "API ID endpoint:         ${GREEN}http://localhost/api/id${NC}"
echo -e "API Health endpoint:     ${GREEN}http://localhost/api/health${NC}"
echo ""
echo -e "${YELLOW}Tips:${NC}"
echo -e "- Refresh the page multiple times to see different container IDs (load balancing)"
echo -e "- Check pod logs: kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/component=backend"
echo -e "- Scale backend: kubectl scale deployment svb-backend -n ${NAMESPACE} --replicas=3"
echo ""
