#!/usr/bin/env bash
# Builds all three services, spins up a local kind cluster, deploys the
# manifests, and verifies the whole order -> inventory -> notification
# chain actually works end-to-end. Safe to re-run — always starts from a
# fresh cluster. Used both for local hands-on runs and by
# .github/workflows/verify-microservices-orchestration.yml.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CLUSTER_NAME="microservices-demo"
NS="microservices-demo"
KIND_VERSION="v0.30.0"
KUBECTL_VERSION="v1.34.0"

install_if_missing() {
  local bin="$1" url="$2"
  if command -v "$bin" >/dev/null 2>&1; then
    return
  fi
  echo "Installing $bin..."
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
  esac
  curl -sL "${url//ARCH/$arch}" -o "/tmp/$bin"
  chmod +x "/tmp/$bin"
  sudo mv "/tmp/$bin" "/usr/local/bin/$bin"
}

install_if_missing kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ARCH"
install_if_missing kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/ARCH/kubectl"

echo "==> Building images"
docker build -t inventory-service:local ./inventory-service
docker build -t notification-service:local ./notification-service
docker build -t order-service:local ./order-service

echo "==> Creating kind cluster ($CLUSTER_NAME)"
kind delete cluster --name "$CLUSTER_NAME" >/dev/null 2>&1 || true
kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml --wait 90s

echo "==> Loading images into the cluster (no registry needed for a local demo)"
kind load docker-image inventory-service:local notification-service:local order-service:local --name "$CLUSTER_NAME"

echo "==> Applying manifests"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/notification-service.yaml
kubectl apply -f k8s/order-service.yaml

echo "==> Waiting for rollouts"
kubectl -n "$NS" rollout status deployment/inventory-service --timeout=120s
kubectl -n "$NS" rollout status deployment/notification-service --timeout=120s
kubectl -n "$NS" rollout status deployment/order-service --timeout=120s

echo "==> Verifying the orchestrated order flow via the NodePort (localhost:8080)"
for i in $(seq 1 15); do
  if curl -sf http://localhost:8080/healthz >/dev/null 2>&1; then break; fi
  sleep 2
done

response=$(curl -sf -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"customer": "demo@example.com", "item": "widget", "quantity": 2}')
echo "$response"

status=$(echo "$response" | grep -o '"status":"[a-z_]*"')
if [[ "$status" != '"status":"confirmed"' ]]; then
  echo "FAIL: order was not confirmed — got: $status" >&2
  exit 1
fi
echo "==> Order confirmed — order-service reached inventory-service and notification-service via K8s service discovery."

echo "==> Cleaning up"
kind delete cluster --name "$CLUSTER_NAME"

echo "==> Done."
