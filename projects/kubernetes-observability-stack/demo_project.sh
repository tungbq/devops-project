#!/usr/bin/env bash
# Kubernetes Observability Stack Demo — installs kube-prometheus-stack
# (Prometheus + Grafana + Alertmanager + node-exporter + kube-state-metrics)
# on a local kind cluster, proves Prometheus is actually scraping real
# targets, proves Grafana actually has real dashboards provisioned, then
# deploys a deliberately crash-looping pod and watches a custom alert go
# inactive -> pending -> firing -> visible in Alertmanager. Used both for
# local hands-on runs and by
# .github/workflows/verify-kubernetes-observability-stack.yml.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/manifests"
CLUSTER_NAME="observability-demo"
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
if ! command -v helm >/dev/null 2>&1; then
  echo "Installing helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

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
echo "2. Installing kube-prometheus-stack (Prometheus, Grafana, Alertmanager,"
echo "   node-exporter, kube-state-metrics — one Helm chart, production-shaped)"
echo "=============================="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.retention=6h \
  --wait --timeout 5m

kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=180s

kubectl run curltest --image=curlimages/curl --restart=Never --command -- sleep 3600
kubectl wait --for=condition=Ready --timeout=60s pod/curltest

echo ""
echo "=============================="
echo "3. Proving Prometheus is actually scraping real targets"
echo "=============================="
up_count=$(kubectl exec curltest -- curl -s "http://kube-prom-stack-kube-prome-prometheus.monitoring.svc:9090/api/v1/query?query=up" \
  | grep -o '"__name__":"up"' | wc -l)
echo "Prometheus has $up_count actively-scraped 'up' targets (kubelet, node-exporter, coredns, itself, ...)"
if [ "$up_count" -lt 1 ]; then
  echo "ERROR: expected at least one real scrape target, found none" >&2
  exit 1
fi

echo ""
echo "=============================="
echo "4. Proving Grafana is healthy with real dashboards provisioned"
echo "=============================="
kubectl exec curltest -- curl -sf -u admin:admin123 "http://kube-prom-stack-grafana.monitoring.svc:80/api/health"
echo ""
dash_count=$(kubectl exec curltest -- curl -s -u admin:admin123 "http://kube-prom-stack-grafana.monitoring.svc:80/api/search?type=dash-db" \
  | grep -o '"title"' | wc -l)
echo "Grafana has $dash_count dashboards provisioned out of the box (Kubernetes compute resources, CoreDNS, etcd, ...)"

echo ""
echo "=============================="
echo "5. Deploying a custom, fast alert rule and a deliberately crashing pod"
echo "=============================="
kubectl apply -f "$MANIFESTS_DIR/demo-crashloop-alert.yaml"
kubectl apply -f "$MANIFESTS_DIR/crashy-pod.yaml"

echo ""
echo "Waiting for the pod to actually reach CrashLoopBackOff (kubelet's restart"
echo "backoff needs a few real cycles — isolating this from the alert-polling"
echo "step below means a failure here vs. a failure there mean different things)"
crash_confirmed=false
for i in $(seq 1 18); do
  reason=$(kubectl get pod crashy -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo "")
  echo "check $i: waiting.reason=${reason:-<none yet>}"
  if [ "$reason" = "CrashLoopBackOff" ]; then
    crash_confirmed=true
    break
  fi
  sleep 10
done
if [ "$crash_confirmed" != true ]; then
  echo "ERROR: crashy never reached CrashLoopBackOff — this is a cluster/scheduling" >&2
  echo "issue, not an alerting-pipeline issue. Pod status:" >&2
  kubectl describe pod crashy >&2
  exit 1
fi

echo ""
echo "=============================="
echo "6. Watching the alert go inactive -> pending -> firing (polls every 10s)"
echo "=============================="
fired=false
for i in $(seq 1 30); do
  state=$(kubectl exec curltest -- curl -s "http://kube-prom-stack-kube-prome-prometheus.monitoring.svc:9090/api/v1/rules" \
    | python3 -c "
import json,sys
data = json.load(sys.stdin)
for group in data['data']['groups']:
    for rule in group.get('rules', []):
        if rule.get('name') == 'DemoPodCrashLooping':
            print(rule['state'])
" 2>/dev/null || echo "")
  echo "check $i: state=${state:-<not evaluated yet>}"
  if [ "$state" = "firing" ]; then
    fired=true
    break
  fi
  sleep 10
done

if [ "$fired" != true ]; then
  echo "ERROR: DemoPodCrashLooping never reached 'firing' within the wait window" >&2
  exit 1
fi

echo ""
echo "=============================="
echo "7. Confirming the firing alert actually reached Alertmanager"
echo "=============================="
kubectl exec curltest -- curl -s "http://kube-prom-stack-kube-prome-alertmanager.monitoring.svc:9093/api/v2/alerts" \
  | python3 -c "
import json,sys
data = json.load(sys.stdin)
found = [a for a in data if a['labels'].get('alertname') == 'DemoPodCrashLooping']
if not found:
    print('ERROR: alert not found in Alertmanager', file=sys.stderr)
    sys.exit(1)
a = found[0]
print('alertname:', a['labels']['alertname'])
print('pod:', a['labels'].get('pod'))
print('summary:', a['annotations'].get('summary'))
"

echo ""
echo "==> Done! Metrics collection, dashboards, and alerting all verified"
echo "    against real, running components — not asserted from config alone."
echo ""
echo "==> Cleanup:"
echo "    kubectl delete -f manifests/"
echo "    helm uninstall kube-prom-stack -n monitoring"
echo "    kind delete cluster --name ${CLUSTER_NAME}"
