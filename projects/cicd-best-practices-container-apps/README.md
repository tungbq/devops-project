# Project: CI/CD Best Practices — Deploy to Azure Container Apps with GitHub Actions

A minimal app, on purpose — the point of this project is the pipeline, not the app. It's a checklist of what a production-grade GitHub Actions -> Azure Container Apps deploy pipeline should have, made concrete and runnable.

## Overview

### Introduction

- Tech stack: `Node.js` (Express), `Docker`, `Terraform`, `Azure Container Apps`, `Azure Container Registry`, `GitHub Actions`
- The app itself is intentionally trivial: two endpoints (`/`, `/health`), no database, no business logic. Every part of this project's complexity is in the pipeline, where it belongs for what this is demonstrating.
- To gain a basic understanding of these tools, you could visit: [**devops-basics**](https://github.com/tungbq/devops-basics)

### What "best practice" means here (checklist)

| Practice | Where |
|---|---|
| No stored cloud credentials — OIDC federated auth only | `deploy...yml`, every `azure/login` step and the Terraform `ARM_USE_OIDC` env |
| Same checks gate a PR and a production deploy — one definition of "passing" | `deploy...yml`'s `verify` job calls `verify...yml` as a reusable workflow |
| Immutable image tags, never `:latest` | `build-and-push` job tags every image with `github.sha` |
| Vulnerability scan is a hard gate, before the image is pushed anywhere | `build-and-push` job, Trivy step before `docker push` |
| Dockerfile itself is linted | `verify...yml`, hadolint step |
| Non-root container, multi-stage build (no dev deps in the runtime image) | `app/Dockerfile` |
| Registry auth via managed identity, not a shared admin password | `terraform/main.tf` (`admin_enabled = false`) + role assignments in `main.tf`/`container-app.tf` |
| Infra changes tracked in remote state, not a laptop/runner disk | `terraform/providers.tf`'s `backend "azurerm" {}` |
| Human approval gate before traffic shifts to a new image | `deploy` job's `environment: production` |
| A typed confirmation on top of the approval gate — a deploy can't fire by accident | `guard` job |
| Concurrency control — deploys can't race each other | `deploy...yml`'s top-level `concurrency:` block |
| Post-deploy smoke test that checks the *right* commit is actually live | `deploy` job's smoke-test step (checks `commitSha` in the response body, not just a 200) |
| Automatic rollback on a failed smoke test | `deploy` job's rollback step |
| Least-privilege, per-job permissions (not a blanket `write-all`) | every job's `permissions:` block |

### Architecture

```
PR / push to main (path: projects/cicd-best-practices-container-apps/**)
         │
         ▼
verify-cicd-best-practices-container-apps.yml
  lint + test → docker build → hadolint → trivy scan → terraform fmt/validate
  (no Azure credentials needed — always runs, always safe)

──────────────────────────────────────────────────────────────

workflow_dispatch (typed "deploy" confirmation required)
         │
         ▼
deploy-cicd-best-practices-container-apps.yml
  guard (confirmation check)
   → verify (reuses the workflow above as a hard gate)
    → infra (terraform apply via OIDC — ACR, Container Apps env, the app)
     → build-and-push (build, scan, push image tagged by commit SHA)
      → deploy  ⟵ requires `production` Environment approval
          az containerapp update → smoke test → rollback if it fails
```

### Prerequisite

- Tools: `node` 22, `docker`, `terraform` >=1.5, `az` CLI (only needed for a real deploy), an Azure subscription (only for a real deploy)
- Basic knowledge of GitHub Actions, Docker, and Terraform

## 1-Run it locally first (no Azure needed)

```bash
cd projects/cicd-best-practices-container-apps
./demo_project.sh
```

Installs deps, lints, runs unit tests, builds the Docker image, runs it and hits both endpoints, and validates the Terraform. This is exactly what CI runs on every PR/push touching this project (`verify-cicd-best-practices-container-apps.yml`) — same checks, same order.

## 2-Deploying for real

This is the part that needs your own Azure subscription — nothing in this repo's CI has Azure credentials, matching every other Azure project here (e.g. [azure-monitoring-dashboard](../azure-monitoring-dashboard/)).

### 2.1-Create the OIDC federated identity (once)

```bash
az ad app create --display-name "gh-cicd-best-practices-container-apps"
# Note the appId (client ID) and the app's objectId from the output above.

az ad sp create --id <appId>

az role assignment create \
  --assignee <appId> \
  --role Contributor \
  --scope /subscriptions/<subscription-id>

az ad app federated-credential create --id <appId> --parameters '{
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:tungbq/devops-project:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

The federated credential's `subject` above only trusts pushes to `main` — see [Microsoft's docs on configuring subject claims](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust) if you want to also trust a specific `environment:` claim instead (tighter, since this project's deploy job already runs under the `production` Environment).

### 2.2-Bootstrap a Terraform state storage account (once)

```bash
az group create --name rg-tfstate --location eastus
az storage account create --name <globally-unique-name> --resource-group rg-tfstate --sku Standard_LRS
az storage container create --name tfstate --account-name <globally-unique-name>
```

### 2.3-Configure the repo

- **Secrets** (Settings → Secrets and variables → Actions):
  `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CI_PRINCIPAL_OBJECT_ID` (the app's *object* ID, not client ID — `az ad app show --id <appId> --query id -o tsv`), `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `TF_STATE_CONTAINER`
- **Environment**: create one named `production` (Settings → Environments) with at least one required reviewer — this is the human approval gate the `deploy` job waits on.

### 2.4-Run it

Actions tab → "Deploy cicd-best-practices-container-apps" → Run workflow → type `deploy` into the confirmation field. Approve the `production` Environment prompt when it appears. Watch it provision infra, build+scan+push the image, then deploy and smoke-test.

### 2.5-Tear down

```bash
cd terraform
terraform init \
  -backend-config="resource_group_name=<rg-tfstate>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=cicd-best-practices-container-apps.tfstate"
terraform destroy
```

## Why this deploys on `workflow_dispatch`, not `push`

A pure "push to main auto-deploys" pipeline is the textbook definition of continuous deployment, and genuinely is best practice once a team trusts its pipeline. But wiring that up here, in a public sample repo, would mean this workflow attempts a real Azure deploy — and fails, loudly, in everyone's PR checks — the moment anyone touches this project's path, unless they've *also* gone and configured OIDC secrets and a state backend first. That's a bad first-run experience for a learning repo. `workflow_dispatch` plus a typed confirmation keeps the deploy real and complete, but opt-in: nothing fires until someone with real Azure credentials configured deliberately runs it. Flipping the trigger to `push: { branches: [main] }` once your own secrets are set up is a one-line change.

## What this project deliberately leaves out

- **Multiple environments (dev/staging/prod)** — the pipeline structure (verify → infra → build → deploy) extends cleanly to a matrix of environments, but a single `production` target keeps this readable as a reference for the pipeline mechanics themselves, which is the actual subject of this project.
- **Blue/green or canary traffic splitting** — `revision_mode = "Single"` (one active revision, full cutover) keeps the rollback logic simple (redeploy the previous image) and easy to follow; Container Apps' multi-revision mode with weighted traffic splitting is a natural next step for a team that wants gradual rollout, not a demo requirement.
- **Alerting on the deployed app** — see [azure-monitoring-dashboard](../azure-monitoring-dashboard/) for the observability side of this stack; wiring its Workbook/alerts to this project's app is a reasonable follow-up, not duplicated here.

## Honesty note on verification

`app/` was built, linted, unit-tested, containerized, and smoke-tested locally in a real Docker container — all genuinely run, not simulated. The Terraform was checked against the actual installed provider schema via `terraform validate` and resolves cleanly with `-backend=false`. Both workflow YAML files were validated with [`actionlint`](https://github.com/rhysd/actionlint) (zero findings), which catches expression-syntax errors, unknown context fields, and malformed `with:` inputs for well-known actions — a stronger check than YAML-syntax validation alone, though still not a substitute for actually running the deploy workflow end to end. That part — the real `workflow_dispatch` run, OIDC exchange, Terraform apply, image push, Container Apps deploy, and smoke test, against a real Azure subscription — has **not** been executed; there are no Azure credentials in the environment this was built in. If you run it for real and something doesn't match what's documented here, please open an issue.
