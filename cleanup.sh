#!/bin/bash
# ==============================================================================
# SVB Webstack Cleanup Script
# ==============================================================================
# This script removes all resources created by the webstack.
#
# USAGE:
#   chmod +x cleanup.sh
#   ./cleanup.sh           # Remove resources but keep cluster
#   ./cleanup.sh --all     # Remove everything including cluster

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLUSTER_NAME="svb-cluster"
NAMESPACE="svb-webstack"

echo -e "${YELLOW}SVB Webstack Cleanup${NC}"
echo ""

# Check for --all flag
if [[ "$1" == "--all" ]]; then
    echo -e "${RED}Deleting entire cluster '${CLUSTER_NAME}'...${NC}"
    kind delete cluster --name ${CLUSTER_NAME}
    echo -e "${GREEN}✓ Cluster deleted${NC}"
    
    echo -e "${YELLOW}Removing Docker images...${NC}"
    docker rmi svb-backend:latest 2>/dev/null || true
    docker rmi svb-frontend:latest 2>/dev/null || true
    echo -e "${GREEN}✓ Images removed${NC}"
else
    echo -e "${YELLOW}Deleting namespace '${NAMESPACE}' and all resources...${NC}"
    kubectl delete namespace ${NAMESPACE} --ignore-not-found
    echo -e "${GREEN}✓ Namespace deleted${NC}"
    echo ""
    echo -e "${YELLOW}Note: Cluster still exists. Use './cleanup.sh --all' to delete everything.${NC}"
fi

echo -e "${GREEN}Cleanup complete!${NC}"
