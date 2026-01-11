#!/bin/bash
# Script to restart Traefik Ingress Controller
# Useful for forcing a new certificate request or reloading config

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Restarting Traefik deployment in kube-system...${NC}"
kubectl rollout restart deployment traefik -n kube-system

echo -e "${BLUE}Waiting for rollout to complete...${NC}"
kubectl rollout status deployment traefik -n kube-system

echo -e "${GREEN}Traefik restarted successfully!${NC}"
echo -e "${BLUE}Current logs (looking for ACME/Certificate events):${NC}"
kubectl logs -n kube-system -l app=traefik --tail=50 | grep -iE "acme|error|level=error" || echo "No recent error logs found."
