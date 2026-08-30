# Project: Azure Monitoring & Dashboard (APIM + Container Apps + Azure Monitor Workbook)

Two sample apps (.NET and Java) behind Azure API Management, running on Azure Container Apps, fully instrumented for distributed tracing — plus a dashboard-as-code Azure Monitor Workbook giving you SLO tracking, RED metrics (request rate, error rate, response time) per service, and a log-filtering panel for root-cause analysis.

## Overview

### Introduction

- Tech stack: `.NET 9` (ASP.NET Core), `Java 21` (Spring Boot), `Docker`, `Azure Container Apps`, `Azure API Management`, `Azure Monitor` / `Application Insights` (workspace-based), `Azure Monitor Workbooks`, `Terraform`
- **dotnet-orders-api** — the only externally-exposed app, sits behind APIM. Accepts an order, calls java-inventory-api to reserve stock. ~15% of orders fail on purpose (a simulated downstream error), so the error-rate/SLO panels have real, non-zero data to show — this is a demo-data generator, not a bug.
- **java-inventory-api** — internal only, reserves stock for an item.
- Both are instrumented for Azure Monitor, but via **two genuinely different, both-valid patterns**: .NET uses the `Azure.Monitor.OpenTelemetry.AspNetCore` SDK (a few lines of startup code); Java uses the Application Insights Java agent (`-javaagent`, zero code changes — auto-instrumentation is the idiomatic Java-ecosystem approach). Worth comparing the two `Dockerfile`s side by side.
- To get basic concepts of these tools, you could visit: [**devops-basics**](https://github.com/tungbq/devops-basics)

### Architecture

```
              ┌──────────────────────┐
  client ───▶ │  Azure API Management │  (Consumption tier, gateway logs → App Insights)
              │  /orders/*             │
              └───────────┬────────────┘
                           │ https
              ┌───────────▼────────────┐        internal-only ingress
              │  dotnet-orders-api      │───────▶ ┌─────────────────────┐
              │  (Container Apps,       │  http   │  java-inventory-api  │
              │   external ingress)     │         │  (Container Apps,    │
              └───────────┬─────────────┘         │   internal ingress)  │
                          │ OpenTelemetry SDK      └──────────┬───────────┘
                          │                          -javaagent (auto-instrument)
                          ▼                                    │
              ┌─────────────────────────────────────────────────┐
              │   Application Insights (workspace-based)          │
              │   → Log Analytics workspace                       │
              └─────────────────────┬───────────────────────────┘
                                    │ KQL
                          ┌─────────▼──────────┐
                          │  Azure Monitor      │
                          │  Workbook           │  SLO · RED metrics · log search
                          └─────────────────────┘
```

One shared Log Analytics workspace backs everything — the apps' own traces (via workspace-based App Insights), the platform's container logs, and APIM's own gateway diagnostic logs all land in the same place, which is what lets one Workbook query across all three.

### Prerequisite

- Tools: `docker`, `dotnet` SDK 9, `java` 21 + `maven` (only needed if you want to build the apps outside Docker), `terraform` >=1.5, `az` CLI, an Azure subscription
- Basic knowledge of Docker, Terraform, and either ASP.NET Core or Spring Boot

## 1-Run it locally first (no Azure needed)

Confirms both apps actually work and actually call each other correctly before you spend any Azure quota on it:

```bash
cd projects/azure-monitoring-dashboard
./demo_project.sh
```

This builds both images, runs them on a shared Docker network, and places a real order through the full `dotnet-orders-api → java-inventory-api` chain. It also runs `terraform validate`/`fmt` and checks the Workbook JSON is well-formed — everything that can be verified **without** an Azure subscription. This is the exact script CI runs on every push/PR that touches this project.

**What this does *not* do:** `terraform apply` against real Azure. There's no Azure credential in this repo's CI (same as every other Azure project here — see e.g. [aks-deploy-monitor-app](../aks-deploy-monitor-app/)), and APIM alone can take 15+ minutes to provision even on the cheapest tier, which wouldn't be a reasonable CI check regardless. Section 3 below is the real deploy walkthrough, meant to be run against your own subscription.

## 2-Run it manually, step by step

```bash
# terminal 1
docker build -t java-inventory-api:local ./apps/java-inventory-api
docker run --rm -p 8081:8081 java-inventory-api:local

# terminal 2
docker build -t dotnet-orders-api:local ./apps/dotnet-orders-api
docker run --rm -p 8080:8080 -e INVENTORY_URL=http://host.docker.internal:8081 dotnet-orders-api:local

# terminal 3
curl -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -d '{"item":"widget","quantity":2}'
```

Neither app needs `APPLICATIONINSIGHTS_CONNECTION_STRING` set to run — both are written to degrade gracefully without it (see the "no crash without Azure" comments in each `Program.cs`/`Dockerfile`), which is also just good practice: a dev environment shouldn't require a cloud subscription to boot the app.

## 3-Deploy to Azure

**Heads up on time and cost:** APIM (even Consumption tier) provisions in roughly 15 minutes. The whole `apply` will take a while — this isn't a "wait 30 seconds" project. Consumption-tier APIM is pay-per-call and Container Apps scales to zero when idle, so idle cost is low, but **run `terraform destroy` when you're done** — nothing here is free to leave running indefinitely.

### 3.1-Push both images to a registry Container Apps can pull from

Container Apps can't use your local `:local`-tagged images directly — they need to live in a real registry. Using Azure Container Registry here, but any registry Container Apps can reach works:

```bash
az acr create --resource-group <your-rg> --name <yourregistry> --sku Basic
az acr login --name <yourregistry>

docker build -t <yourregistry>.azurecr.io/dotnet-orders-api:v1 ./apps/dotnet-orders-api
docker push <yourregistry>.azurecr.io/dotnet-orders-api:v1

docker build -t <yourregistry>.azurecr.io/java-inventory-api:v1 ./apps/java-inventory-api
docker push <yourregistry>.azurecr.io/java-inventory-api:v1
```

### 3.2-Deploy the infrastructure

```bash
cd terraform
terraform init

terraform apply \
  -var="apim_publisher_name=Your Name" \
  -var="apim_publisher_email=you@example.com" \
  -var="dotnet_orders_api_image=<yourregistry>.azurecr.io/dotnet-orders-api:v1" \
  -var="java_inventory_api_image=<yourregistry>.azurecr.io/java-inventory-api:v1"
```

### 3.3-Generate some traffic

The dashboard has nothing to show until requests actually flow through it:

```bash
GATEWAY_URL=$(terraform output -raw apim_gateway_url)
for i in $(seq 1 40); do
  curl -s -X POST "${GATEWAY_URL}/orders/api/orders" \
    -H "Content-Type: application/json" \
    -d '{"item":"widget","quantity":1}' -o /dev/null
  sleep 2
done
```

Give it a few minutes — Application Insights ingestion isn't instant.

### 3.4-Open the Workbook

```bash
terraform output workbook_resource_id
```

In the Azure Portal: **Azure Monitor → Workbooks → (Public/Shared) →** find "Service health — SLO, RED metrics, root-cause search" (or open the resource ID directly). Pick a service from the dropdown at the top; every panel below updates.

### 3.5-Tear down

```bash
terraform destroy \
  -var="apim_publisher_name=Your Name" \
  -var="apim_publisher_email=you@example.com" \
  -var="dotnet_orders_api_image=<yourregistry>.azurecr.io/dotnet-orders-api:v1" \
  -var="java_inventory_api_image=<yourregistry>.azurecr.io/java-inventory-api:v1"
```

## 4-Reading the dashboard

- **Request rate / Error rate / Response time percentiles** — the classic RED metrics, per service, over your chosen time range.
- **SLO tile** — "% of requests under 500ms" in the selected window. The 500ms/95% numbers are hardcoded in the Workbook's KQL as a demo target — see the query's own comment for where to change them to a real SLO.
- **Root-cause log search** — type anything (an order ID, an exception type, a message fragment) into the **Log filter** parameter; the table below shows matching traces and exceptions for the selected service. Each row has an `operation_Id` — **copy it and paste it into Application Insights → Investigate → Transaction search** in the Portal to see the complete distributed trace for that request, including the cross-service dotnet→java hop. (There's no verified-working native "click straight from a Workbook row into the transaction view" link — some blog posts claim one, but it isn't in Microsoft's own documented Workbook link-action schema, and this project would rather tell you the honest two-step path than ship a link that might silently 404.)
- **APIM gateway logs vs. app-level traces** are two different views of the same traffic — `ApiManagementGatewayLogs` (what the gateway saw) vs. `AppRequests` (what dotnet-orders-api itself recorded). Comparing them is a real, useful debugging technique (e.g. a request APIM logged but the app never recorded means the app crashed before handling it).

## What this project deliberately leaves out

- **A real database or message queue** — same reasoning as [microservices-orchestration](../microservices-orchestration/): in-memory state is enough to demonstrate the observability story without dragging in unrelated lessons (StatefulSets/PVCs, outbox patterns).
- **Alerting** (Azure Monitor Alerts / Action Groups on the SLO burning) — the Workbook shows you the data; wiring alerts on top is a real, separate, equally-valid follow-up project.
- **Custom domain / TLS on APIM** — APIM's default `azure-api.net` domain is fine for a demo; a real deployment would want its own domain and certificate.
- **Azure Managed Grafana** — considered and deliberately not used here; see this project's planning discussion for the reasoning (Workbooks won on cost and on fit for the log-filtering requirement specifically).

## Honesty note on verification

Every Terraform resource and the Workbook JSON were checked against the actual installed provider schema (`terraform providers schema -json`) and `terraform validate`/`terraform plan` — not just written from memory or docs prose. `terraform plan` resolves the entire resource graph correctly and only stops at the Azure authentication step (no credentials exist in the environment this was built in) — meaning every reference, interpolation, and attribute name is confirmed structurally correct, right up to the boundary of actually needing a live subscription. It has **not** been run through a real `terraform apply` — if you hit something that doesn't match reality once you do, that's the one part of this project that's genuinely untested; please open an issue.
