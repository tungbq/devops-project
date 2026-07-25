#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Cleaning previous build outputs..."
rm -rf dist build ./*.egg-info .venv

echo "=== BUILD ==="
python3 -m venv .venv
source .venv/bin/activate
pip install -q -r requirements-dev.txt
python -m build
ls -l dist/

echo "=== TEST ==="
pip install -q dist/*.whl
pytest tests/ -v

echo "=== DEPLOY (smoke) ==="
simple-ci-app add 2 3

deactivate
echo "Pipeline finished successfully."
