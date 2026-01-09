#!/bin/sh

source ./config.sh

docker build -t svb-frontend:latest ./frontend

kind load docker-image svb-frontend:latest --name $CLUSTER_NAME

kubectl rollout restart deployment svb-frontend -n $NAMESPACE

kubectl wait --namespace $NAMESPACE \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=frontend \
    --timeout=120s
    
echo "Frontend updated successfully"