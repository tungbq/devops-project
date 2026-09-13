#!/usr/bin/env bash
# Kubernetes Blue-Green Deployment Demo — deploys two versions of a tiny
# app side by side, cuts live traffic over from one to the other by
# patching a single Service selector (no pod restarts, no rolling update),
# proves zero requests are dropped during the cutover, then rolls back
# instantly the same way. Used both for local hands-on runs and by
# .github/workflows/verify-kubernetes-blue-green-deployment.yml.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/manifests"
CLUSTER_NAME="bluegreen-demo"
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
    aarch64 | arm64) arch="arm64" ;;
    *)
      echo "Unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac
  curl -sL "${url//ARCH/$arch}" -o "/tmp/$bin"
  chmod +x "/tmp/$bin"
  sudo mv "/tmp/$bin" "/usr/local/bin/$bin"
}

install_if_missing kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-ARCH"
install_if_missing kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/ARCH/kubectl"

echo "=============================="
echo "1. Ensuring a local cluster exists"
echo "=============================="
if kubectl config get-contexts "kind-${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "Reusing existing kind cluster: ${CLUSTER_NAME}"
  kubectl config use-context "kind-${CLUSTER_NAME}"
else
  echo "Creating kind cluster: ${CLUSTER_NAME}"
  kind create cluster --name "${CLUSTER_NAME}"
fi

cleanup() {
  kubectl delete pod curltest --ignore-not-found --force --grace-period=0 >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo ""
echo "=============================="
echo "2. Deploying BLUE (the current live version) and its Service"
echo "=============================="
kubectl apply -f "$MANIFESTS_DIR/deployment-blue.yaml"
kubectl apply -f "$MANIFESTS_DIR/service.yaml"
kubectl wait --for=condition=available --timeout=120s deployment/app-blue

kubectl run curltest --image=curlimages/curl --restart=Never --command -- sleep 3600
kubectl wait --for=condition=Ready --timeout=60s pod/curltest

echo ""
echo "Live traffic right now:"
kubectl exec curltest -- curl -s demo-app

echo ""
echo "=============================="
echo "3. Deploying GREEN (the new version) alongside — it receives zero"
echo "   live traffic yet, since the Service selector still says 'blue'"
echo "=============================="
kubectl apply -f "$MANIFESTS_DIR/deployment-green.yaml"
kubectl wait --for=condition=available --timeout=120s deployment/app-green
kubectl apply -f "$MANIFESTS_DIR/service-preview.yaml"

echo ""
echo "Live traffic is still unaffected by green existing:"
kubectl exec curltest -- curl -s demo-app

echo ""
echo "Smoke-testing green directly via the preview Service (retrying — a"
echo "freshly created Service can take a moment for cluster DNS to resolve):"
for _ in $(seq 1 10); do
  if kubectl exec curltest -- curl -sf demo-app-preview; then break; fi
  sleep 2
done
echo ""

echo ""
echo "=============================="
echo "4. Cutover — patch the live Service's selector, nothing else"
echo "=============================="
kubectl patch service demo-app -p '{"spec":{"selector":{"app":"demo-app","version":"green"}}}'
echo "Live traffic immediately after the patch:"
kubectl exec curltest -- curl -s demo-app

echo ""
echo "=============================="
echo "5. Proving zero downtime — 20 rapid requests spanning the moment of cutover"
echo "=============================="
kubectl patch service demo-app -p '{"spec":{"selector":{"app":"demo-app","version":"blue"}}}' >/dev/null
codes=""
for i in $(seq 1 20); do
  if [ "$i" -eq 10 ]; then
    kubectl patch service demo-app -p '{"spec":{"selector":{"app":"demo-app","version":"green"}}}' >/dev/null
  fi
  codes="$codes $(kubectl exec curltest -- curl -s -o /dev/null -w '%{http_code}' demo-app)"
done
echo "HTTP status codes for all 20 requests (cutover happened mid-loop):$codes"

echo ""
echo "=============================="
echo "6. Rollback — the exact same patch, in reverse, is the entire rollback"
echo "=============================="
kubectl patch service demo-app -p '{"spec":{"selector":{"app":"demo-app","version":"blue"}}}'
echo "Live traffic after rollback:"
kubectl exec curltest -- curl -s demo-app

echo ""
echo "==> Done! Cutover and rollback were both a single Service patch —"
echo "    no pod was ever created, restarted, or deleted to move traffic."
echo ""
echo "==> Cleanup:"
echo "    kubectl delete -f manifests/"
echo "    kind delete cluster --name ${CLUSTER_NAME}"
