# Project: Microservices Orchestration

Build a small microservices-based application and use Kubernetes to orchestrate it — service discovery, config management, health probes, and scaling.

## Overview

### Introduction

- Tech stack: `Python` (FastAPI), `Docker`, `Kubernetes` (via [kind](https://kind.sigs.k8s.io/))
- Three services, each independently deployable and independently scalable:
  - **order-service** — the only externally-exposed service; accepts an order, then calls the other two.
  - **inventory-service** — reserves stock for an item.
  - **notification-service** — "sends" a confirmation (logs it in-memory; this is a demo, not a real notifier).
- The point of this project isn't the business logic (it's deliberately trivial) — it's what Kubernetes does *around* the three services: **service discovery** (order-service never hardcodes an IP), **config as data** (a ConfigMap, not code, tells order-service where its dependencies live), **health probes** (readiness/liveness), and **horizontal scaling** (`kubectl scale` and a real HPA).
- To gain a basic understanding of Kubernetes, you could visit: [**Kubernetes**](https://kubernetes.io/) and [**devops-basics/kubernetes**](https://github.com/tungbq/devops-basics)

### Architecture

```
                     ┌─────────────────────┐
   client ──POST──▶  │   order-service      │  (NodePort, replicas: 2)
                     │   (the only one       │
                     │    exposed outside)   │
                     └─────────┬─────────────┘
                     ConfigMap  │  (INVENTORY_URL, NOTIFICATION_URL —
                     injects ──▶│   K8s DNS short names, not IPs)
                               ┌┴──────────────┐
                     ┌─────────┴───┐    ┌───────┴──────────┐
                     │ inventory-   │    │ notification-    │
                     │ service      │    │ service           │
                     │ (ClusterIP)  │    │ (ClusterIP)       │
                     └──────────────┘    └───────────────────┘
```

### Prerequisite

- Basic knowledge about Docker and Kubernetes (Deployments, Services, ConfigMaps)
- Tools: `docker`, `curl`. `kind` and `kubectl` are auto-installed by the demo script if missing (see [`demo_project.sh`](./demo_project.sh)).

## 1-Run the whole thing

The fastest way to see it work end-to-end (build → local kind cluster → deploy → verify → tear down):

```bash
cd projects/microservices-orchestration
./demo_project.sh
```

This is the exact script [`.github/workflows/verify-microservices-orchestration.yml`](../../.github/workflows/verify-microservices-orchestration.yml) runs on every push/PR that touches this project — verified in CI, not just locally.

## 2-Run it step by step (to actually poke around)

### 2.1-Build the images

```bash
docker build -t inventory-service:local ./inventory-service
docker build -t notification-service:local ./notification-service
docker build -t order-service:local ./order-service
```

### 2.2-Create a local cluster and load the images into it

`kind` clusters can't `docker pull` your locally-built images — there's no registry — so they're loaded directly into the cluster's node instead.

```bash
kind create cluster --name microservices-demo --config kind-config.yaml
kind load docker-image inventory-service:local notification-service:local order-service:local --name microservices-demo
```

### 2.3-Deploy

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/notification-service.yaml
kubectl apply -f k8s/order-service.yaml
```

### 2.4-Place an order

`kind-config.yaml` maps the cluster's NodePort 30080 to `localhost:8080`:

```bash
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"customer": "you@example.com", "item": "widget", "quantity": 2}'
```

The response's `"pod"` fields show three *different* pod names — proof the request actually crossed process/network boundaries via Kubernetes Services, not an in-process function call:

```json
{
  "pod": "order-service-...",
  "orderId": "...",
  "status": "confirmed",
  "reservation": { "pod": "inventory-service-...", "item": "widget", "reserved": 2, "remaining": 8 },
  "notification": { "pod": "notification-service-...", "to": "you@example.com", "...": "..." }
}
```

## 3-Scaling

### 3.1-Manual scaling

```bash
kubectl -n microservices-demo scale deployment order-service --replicas=4
kubectl -n microservices-demo get pods -l app=order-service
```

Fire a few orders and watch the `"pod"` field in the response rotate across replicas — the Service load-balances across whichever pods are `Ready`:

```bash
for i in $(seq 1 6); do
  curl -s -X POST http://localhost:8080/orders \
    -H "Content-Type: application/json" \
    -d '{"customer":"x@test.com","item":"widget","quantity":1}' \
    | grep -o '"pod":"[a-z0-9-]*"' | head -1
done
```

### 3.2-Autoscaling (HPA)

`kind` doesn't ship [metrics-server](https://github.com/kubernetes-sigs/metrics-server) by default — the HPA (`k8s/order-service-hpa.yaml`) exists in the cluster either way, it just has no CPU metric to scale on until metrics-server is installed. `kind`'s kubelet also uses a self-signed cert metrics-server rejects by default, hence the `--kubelet-insecure-tls` patch:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deployment/metrics-server

kubectl apply -f k8s/order-service-hpa.yaml
kubectl -n microservices-demo get hpa order-service --watch
```

Verified working: `kubectl top pods` and `kubectl describe hpa order-service` both report real CPU numbers a few seconds after metrics-server comes up (not "unknown"). Generating enough load to actually trigger a scale-up (sustained >50% CPU for a few minutes) is left as an exercise — a simple loop of curl requests in a `while true` won't generate meaningful CPU load against an app this trivial; a proper load generator (`hey`, `k6`, or similar) is the honest way to do it.

## 4-Tear down

```bash
kind delete cluster --name microservices-demo
```

## What this project deliberately leaves out

- **A real database.** Stock/notifications are in-memory and reset on pod restart — adding Postgres here would teach StatefulSets/PVCs, which is a different (and equally valid) lesson from "how do three stateless services find and talk to each other."
- **A service mesh (Istio/Linkerd).** This repo already has [aks-istio-application](../aks-istio-application/) and [aks-nginx-with-istio](../aks-nginx-with-istio/) for that. This project is the "plain Kubernetes" baseline those build on top of.
- **A real message queue.** order-service calls notification-service synchronously and just swallows the error if it fails (see the code comment in `order-service/app.py`) — a real system would use an outbox pattern or a queue. That's a distinct lesson from orchestration basics.
