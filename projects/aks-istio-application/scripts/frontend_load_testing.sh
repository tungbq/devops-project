#!/bin/bash

PAGE_URL=$1
# To get page, run: `kubectl get svc aks-istio-ingressgateway-external -n aks-istio-ingress`
## Usage: ./frontend_load_testing.sh 1.2.3.4

echo "Testing frontend page workload..."
for i in $(seq 1 1000); do
  echo "Try number $i..."
  curl -s -o /dev/null "$PAGE_URL"
  sleep 1
done
echo "Testing frontend page completed!"
