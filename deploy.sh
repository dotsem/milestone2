CLUSTER_NAME="svb-cluster"
NAMESPACE="svb-webstack"

# creëer kind cluster met de kind config
kind create cluster --config kind-config.yaml --name ${CLUSTER_NAME}

#  check of we met de juiste cluster aan het werken zijn
kubectl cluster-info --context kind-${CLUSTER_NAME} > /dev/null 2>&1

# installeer prometheus via helm en wacht tot het geinstalleerd is
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -wait

# voeg argoCD repo toe en update
helm repo add argo https://argoproj.github.io/argo-helm > /dev/null 2>&1
helm repo update > /dev/null 2>&1

# wacht totdat argocd is geinstalleerd
helm install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --set server.service.type=ClusterIP \
        --wait

# bouw de docker containers en laad ze in in kind
docker build -t svb-backend:latest ./backend
docker build -t svb-frontend:latest ./frontend
docker build -t svb-database:latest ./database

kind load docker-image svb-backend:latest --name ${CLUSTER_NAME}
kind load docker-image svb-frontend:latest --name ${CLUSTER_NAME}
kind load docker-image svb-database:latest --name ${CLUSTER_NAME}

# laad configs in in de juiste volgorde
kubectl apply -f k8s/traefik-crds.yaml
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/duckdns-secret.yaml
kubectl apply -f k8s/traefik.yaml
kubectl apply -f argocd/application.yaml

kubectl wait --namespace ${NAMESPACE} \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=database \
    --timeout=120s

kubectl wait --namespace ${NAMESPACE} \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=backend \
    --timeout=120s

kubectl wait --namespace ${NAMESPACE} \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=backend \
    --timeout=120s

echo -e "Deployment klaar"