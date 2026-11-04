#!/usr/bin/env bash
# Creates a local minikube cluster and installs Argo CD for the demo.
set -euo pipefail

minikube start -p argocd-demo --cpus 2 --memory 4096

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

# Dex off, plain HTTP (local only), and Git checked every 30s instead of 3 min
helm install argocd argo/argo-cd -n argocd --create-namespace \
  --set dex.enabled=false \
  --set 'configs.params.server\.insecure=true' \
  --set 'configs.cm.timeout\.reconciliation=30s'

kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

echo
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
echo
echo "Open the UI with:  kubectl port-forward -n argocd svc/argocd-server 8080:80"
echo "Then browse to http://localhost:8080 and log in as admin."
