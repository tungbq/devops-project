#!/usr/bin/env bash
# Verifies everything that CAN be verified without an Azure subscription —
# the same checks verify-cicd-best-practices-container-apps.yml runs in CI:
# lint, unit tests, Docker build, and Terraform fmt/validate. It does NOT
# run deploy-cicd-best-practices-container-apps.yml's actual deploy — that
# needs a real Azure subscription, OIDC federated credentials, and a
# pre-existing Terraform state storage account, none of which exist here.
# See README "Deploying for real".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> App: install, lint, test"
cd "$SCRIPT_DIR/app"
npm ci
npm run lint
npm test

echo "==> App: Docker build"
docker build \
  --build-arg BUILD_VERSION=local-verify \
  --build-arg BUILD_COMMIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo local)" \
  -t cicd-best-practices-container-apps:verify .

echo "==> App: smoke-run the image"
CONTAINER=cicd-cac-verify
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --rm --name "$CONTAINER" -p 3098:3000 cicd-best-practices-container-apps:verify >/dev/null
trap 'docker rm -f "$CONTAINER" >/dev/null 2>&1 || true' EXIT

ok=""
for i in $(seq 1 10); do
  if curl -sf http://localhost:3098/health >/dev/null 2>&1; then ok=1; break; fi
  sleep 1
done
if [ -z "$ok" ]; then
  echo "FAIL: container never became healthy" >&2
  exit 1
fi
curl -sf http://localhost:3098/
echo
echo "==> App image OK"

if command -v trivy >/dev/null 2>&1; then
  echo "==> Vulnerability scan (trivy found locally)"
  trivy image --severity CRITICAL,HIGH --exit-code 1 --ignore-unfixed cicd-best-practices-container-apps:verify
else
  echo "==> Skipping vulnerability scan — trivy not installed locally. CI runs this step regardless (verify-cicd-best-practices-container-apps.yml)."
fi

echo "==> Terraform: fmt, init, validate (no Azure credentials needed for this)"
cd "$SCRIPT_DIR/terraform"
terraform fmt -check -recursive
terraform init -backend=false -input=false >/dev/null
terraform validate

echo "==> Done. Everything that can be verified without an Azure subscription has been verified."
echo "    To deploy for real: see README.md 'Deploying for real'."
