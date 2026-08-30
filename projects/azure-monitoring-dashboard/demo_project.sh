#!/usr/bin/env bash
# Verifies everything that CAN be verified without a real Azure subscription:
# both sample apps build, run, and talk to each other correctly (containerized,
# same as they'd run on Azure Container Apps), and the Terraform + Workbook
# JSON are syntactically valid. It does NOT run `terraform apply` — there is
# no Azure credential in CI for this repo (same as every other Azure project
# here), and APIM alone can take 30-45+ minutes to provision even on the
# Consumption tier, which wouldn't be a reasonable CI check regardless. See
# README "Deploying to Azure" for the real `terraform apply` walkthrough,
# meant to be run against your own subscription.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

NETWORK="azmon-demo-verify"
JAVA_CONTAINER="azmon-verify-java"
DOTNET_CONTAINER="azmon-verify-dotnet"

cleanup() {
  docker rm -f "$JAVA_CONTAINER" "$DOTNET_CONTAINER" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Building images"
docker build -t java-inventory-api:local ./apps/java-inventory-api
docker build -t dotnet-orders-api:local ./apps/dotnet-orders-api

echo "==> Running both containers on a shared network (no Azure needed for this part)"
docker network create "$NETWORK" >/dev/null
docker run -d --name "$JAVA_CONTAINER" --network "$NETWORK" java-inventory-api:local >/dev/null
docker run -d --name "$DOTNET_CONTAINER" --network "$NETWORK" -p 8180:8080 \
  -e "INVENTORY_URL=http://${JAVA_CONTAINER}:8081" dotnet-orders-api:local >/dev/null

echo "==> Waiting for both services to be healthy"
for i in $(seq 1 20); do
  if curl -sf http://localhost:8180/health >/dev/null 2>&1; then break; fi
  sleep 2
done

echo "==> Placing a real order through the full chain (dotnet-orders-api -> java-inventory-api)"
# dotnet-orders-api simulates a ~15% failure rate on purpose (see Program.cs)
# so the SLO/error-rate dashboard has real non-zero data to show. That means
# a single request has a real, non-negligible chance of hitting the
# simulated failure — retry a few times so this check verifies the
# dotnet->java chain itself, not the (intentional) failure-injection.
response=""
for attempt in $(seq 1 8); do
  if response=$(curl -sf -X POST http://localhost:8180/api/orders \
    -H "Content-Type: application/json" \
    -d '{"item": "widget", "quantity": 2}'); then
    break
  fi
  echo "    attempt $attempt hit the simulated failure rate or wasn't ready yet, retrying..."
  response=""
  sleep 1
done

if [ -z "$response" ] || ! echo "$response" | grep -q '"item":"widget"'; then
  echo "FAIL: order did not go through the dotnet -> java chain as expected" >&2
  exit 1
fi
echo "$response"
echo "==> Order confirmed — dotnet-orders-api successfully called java-inventory-api across a real container network."

echo "==> Validating Terraform (no Azure credentials needed for validate/fmt)"
cd "$SCRIPT_DIR/terraform"
terraform fmt -check -recursive
terraform init -backend=false -input=false >/dev/null
terraform validate

echo "==> Validating the Workbook JSON is well-formed"
python3 -m json.tool "$SCRIPT_DIR/workbook/slo-dashboard.workbook.json" >/dev/null

echo "==> Done. Everything that can be verified without an Azure subscription has been verified."
echo "    To actually deploy: see README.md '3-Deploy to Azure'."
