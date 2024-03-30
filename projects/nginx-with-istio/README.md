# Nginx Ingress with Istio service mesh

## Doc

- https://docs.nginx.com/nginx-ingress-controller/tutorials/nginx-ingress-istio/
- https://platform9.com/learn/v1.0/tutorials/nginix-controller-via-yaml
- https://gist.github.com/petitviolet/d36f33d145d0bbf4b54eb187b79d0244
- https://cloud.google.com/endpoints/docs/openapi/custom-nginx

## Architecture

- Refer: https://docs.nginx.com/nginx-ingress-controller/tutorials/nginx-ingress-istio/
- Traefik Ingress can be implemented as an entry point to an Istio service mesh

## Prerequisite

- Deploy fresh cluster: devops-project/projects/terraform-aks-cluster (at least `D3_v2` node to avoid insufficent CPU issue)
- Enable istio (aks-istio-system ns) and deploy app (default ns): devops-project/projects/aks-istio-application (Can skip step 5 - istio gateways)
- Integrate Nginx with istio

## Steps

### 0-Prepare environment

```bash
export DEVOPS_PROJECT_PATH="/mnt/d/CODING/GITHUB/OPEN-SOURCE/my-project/devops-project"
```

### 1-Deploy fresh cluster

- Check [terraform-aks-cluster](../terraform-aks-cluster/)

### 2-Enable istio

- Istio (aks-istio-system ns) and deploy app (default ns)
- Check [aks-istio-application](../aks-istio-application/) - skip step #5
- Enable side car enjection for nginx

```bash
kubectl create ns nginx-ingress
# Check current istio version on AKS
az aks show --resource-group ${RESOURCE_GROUP} --name ${CLUSTER} | grep asm
kubectl label namespace nginx-ingress istio.io/rev=asm-1-20 --overwrite

# Check labels
kubectl get namespaces -A --show-labels
```

### 3-Nginx deploy

```bash
kubectl apply -f $DEVOPS_PROJECT_PATH/projects/nginx-with-istio/k8s_manifest/nginx-ingress.yaml
```
