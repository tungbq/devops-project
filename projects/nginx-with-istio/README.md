# Nginx Ingress with Istio service mesh

## Doc

- https://docs.nginx.com/nginx-ingress-controller/tutorials/nginx-ingress-istio/

## Architecture

- Refer: https://docs.nginx.com/nginx-ingress-controller/tutorials/nginx-ingress-istio/
- Traefik Ingress can be implemented as an entry point to an Istio service mesh

## Prerequisite

- Deploy fresh cluster: devops-project/projects/terraform-aks-cluster (at least `D3_v2` node to avoid insufficent CPU issue)
- Enable istio (aks-istio-system ns) and deploy app (default ns): devops-project/projects/aks-istio-application (Can skip step 5 - istio gateways)
- Integrate Nginx with istio

## Steps

### 1-Deploy fresh cluster

- Check [terraform-aks-cluster](../terraform-aks-cluster/)

### 2-Enable istio

- Istio (aks-istio-system ns) and deploy app (default ns)
- Check [aks-istio-application](../aks-istio-application/)

### 3-Nginx deploy
