# Project: Kubernetes Observability Stack

This project installs a production-shaped observability stack — Prometheus, Grafana, Alertmanager, node-exporter, and kube-state-metrics — onto a Kubernetes cluster with one Helm chart, then proves each of the three pillars actually works: real metrics are being scraped, real dashboards are provisioned, and a real alert fires end-to-end when something breaks.

## Overview

### Introduction

- Tech stack: `kubernetes`, `helm`, `prometheus`, `grafana`, `alertmanager`
- To get the basic concept of these tools individually, see [**devops-basics/prometheus**](https://github.com/tungbq/devops-basics/blob/main/topics/prometheus/README.md) and [**devops-basics/grafana**](https://github.com/tungbq/devops-basics/blob/main/topics/grafana/README.md) — this project is about wiring them together into one working stack, not re-teaching either tool
- Runs entirely on a local `kind` cluster — no cloud account needed

### Prerequisite

- You have `docker`, `kind`, `kubectl`, and `helm` installed on your machine
- Basic knowledge about Kubernetes and Prometheus's data model (metrics, labels, PromQL)

### Why this project, and not just the individual topics?

Reading about Prometheus and reading about Grafana separately doesn't tell you whether the wiring between them (and Alertmanager, and the exporters that actually produce data) is correct. This project deploys the whole chain and checks each link:

1. **Collection** — is Prometheus actually scraping real targets, or just running with an empty config?
2. **Visualization** — does Grafana actually have dashboards with real data sources, or just a login page?
3. **Alerting** — if a `PrometheusRule` says "alert when X happens", does breaking X for real actually produce a firing alert in Alertmanager — not just a green checkmark in a YAML file?

## 1-Install kube-prometheus-stack

- `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
- `helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace`
- This one chart deploys the Prometheus Operator, a `Prometheus` custom resource, Alertmanager, Grafana (with a set of Kubernetes dashboards pre-provisioned), `kube-state-metrics` (Kubernetes object state as metrics), and `node-exporter` (host-level metrics) — the same shape most real clusters run

## 2-Verify collection is real

- Query Prometheus directly: `curl http://<prometheus-svc>:9090/api/v1/query?query=up`
- A fresh install already has over a dozen actively-scraped targets — kubelet, node-exporter, CoreDNS, Alertmanager, and Prometheus itself — with zero app-specific configuration

## 3-Verify visualization is real

- `curl -u admin:<password> http://<grafana-svc>/api/health` → `{"database":"ok", ...}`
- `curl -u admin:<password> http://<grafana-svc>/api/search?type=dash-db` → ~29 dashboards, already wired to the Prometheus data source (Kubernetes compute resources, CoreDNS, etcd, Alertmanager overview, and more)

## 4-Write a fast custom alert and prove it fires

- The chart ships a built-in `KubePodCrashLooping` alert, but its `for: 15m` is tuned for production noise reduction, not for watching it fire in a demo
- [`manifests/demo-crashloop-alert.yaml`](./manifests/demo-crashloop-alert.yaml) defines the same underlying signal (`kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}`) with `for: 30s`
- Apply [`manifests/crashy-pod.yaml`](./manifests/crashy-pod.yaml) — a pod that deliberately exits 1 immediately, so Kubernetes puts it into `CrashLoopBackOff`
- Poll `curl http://<prometheus-svc>:9090/api/v1/rules` and watch the alert's `state` field move `inactive` → `pending` → `firing`
- Confirm it actually reached Alertmanager, not just Prometheus's internal state: `curl http://<alertmanager-svc>:9093/api/v2/alerts`

## 5-Bonus

All of the above, scripted end-to-end (install the stack → verify collection → verify dashboards → deploy the alert + crashing pod → watch it fire → confirm it reached Alertmanager), is in [demo_project.sh](./demo_project.sh).

## Related link

- https://github.com/prometheus-operator/kube-prometheus
- https://prometheus.io/docs/prometheus/latest/querying/api/
- https://prometheus.io/docs/alerting/latest/configuration/
- https://github.com/tungbq/devops-basics/blob/main/topics/prometheus/README.md
- https://github.com/tungbq/devops-basics/blob/main/topics/grafana/README.md
