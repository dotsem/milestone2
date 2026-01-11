#!/bin/sh

source ./config.sh

docker build -t svb-backend:latest ./backend

kind load docker-image svb-backend:latest --name $CLUSTER_NAME

kubectl rollout restart deployment svb-backend -n $NAMESPACE

kubectl wait --namespace $NAMESPACE \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=backend \
    --timeout=120s
    
echo "Backend updated successfully"