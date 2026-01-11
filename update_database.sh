#!/bin/sh

source ./config.sh


kubectl rollout restart deployment svb-database -n $NAMESPACE

kubectl wait --namespace $NAMESPACE \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=database \
    --timeout=120s
    
echo "Database updated successfully"