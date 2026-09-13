# Project: Kubernetes Blue-Green Deployment

This project demonstrates the blue-green deployment strategy on Kubernetes: two full versions of an app run side by side, and switching live traffic between them is a single `Service` selector patch — no pod restart, no rolling update, and rollback is the exact same patch in reverse.

## Overview

### Introduction

- Tech stack: `kubernetes`, `docker`
- To get the basic concept of Kubernetes, you could visit: [**devops-basics/k8s**](https://github.com/tungbq/devops-basics/blob/main/topics/k8s/README.md)
- The demo runs entirely on a local `kind` cluster — no cloud account needed

### Prerequisite

- You have `docker` and `kind` installed on your machine
- `kubectl` configured against your cluster
- Basic knowledge about Kubernetes (`Deployment`, `Service`, label selectors)

### Why blue-green, not a rolling update?

A Kubernetes rolling update replaces pods gradually — for a window of time, both old and new versions are live *and* you can't instantly go back to 100% old without another rollout. Blue-green keeps both versions fully deployed simultaneously:

- **Cutover is atomic and instant** — one `kubectl patch service`, not a gradual pod-by-pod replacement
- **Rollback is equally instant** — the same patch, in reverse, no need to "roll forward" to an old image again
- **The new version can be smoke-tested with real traffic before going live** — via a second, "preview" Service that always points at green, while the main Service still serves 100% blue
- **Trade-off, stated plainly**: you run 2x the pod count while both versions coexist, and this demo doesn't cover stateful workloads (a shared database between blue and green needs its own compatibility story — out of scope here)

## 1-Deploy blue (the current live version)

- `kubectl apply -f manifests/deployment-blue.yaml`
- `kubectl apply -f manifests/service.yaml` — the `demo-app` Service, selecting `version: blue`
- Verify: `kubectl run curltest --image=curlimages/curl --restart=Never --command -- sleep 3600` then `kubectl exec curltest -- curl -s demo-app` → `Hello from BLUE (v1)`

## 2-Deploy green alongside, without touching live traffic

- `kubectl apply -f manifests/deployment-green.yaml` — a second, independent `Deployment`, labeled `version: green`
- `kubectl apply -f manifests/service-preview.yaml` — `demo-app-preview`, a Service that *always* points at green, for smoke-testing
- `kubectl exec curltest -- curl -s demo-app` still returns `Hello from BLUE (v1)` — green existing changes nothing about live traffic
- `kubectl exec curltest -- curl -s demo-app-preview` returns `Hello from GREEN (v2)` — green is verified healthy and correct *before* it ever sees real traffic

## 3-Cut over

- `kubectl patch service demo-app -p '{"spec":{"selector":{"app":"demo-app","version":"green"}}}'`
- `kubectl exec curltest -- curl -s demo-app` now returns `Hello from GREEN (v2)` — immediately, with zero pods created/restarted/deleted

## 4-Verify zero downtime across the cutover

- Fire a burst of requests, patching the selector partway through the burst
- Every single request gets a `200`, whether it landed before or after the cutover — see `demo_project.sh` step 5

## 5-Roll back

- `kubectl patch service demo-app -p '{"spec":{"selector":{"app":"demo-app","version":"blue"}}}'`
- Traffic is back on blue immediately — this is the entire rollback procedure, no redeploy needed

## 6-Bonus

All of the above, scripted end-to-end (cluster → blue → green → preview → cutover → zero-downtime proof → rollback), is in [demo_project.sh](./demo_project.sh).

## Related link

- https://kubernetes.io/docs/concepts/services-networking/service/
- https://martinfowler.com/bliki/BlueGreenDeployment.html
- https://github.com/tungbq/devops-basics/blob/main/topics/k8s/README.md
