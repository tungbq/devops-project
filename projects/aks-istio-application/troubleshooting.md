## Troubleshoot common issues

### Incase we want to redeploy/delete some helm release

- Run `helm delete $release -n $namespace`, for example:

```bash
helm delete kube-prometheus-stack -n aks-istio-system
helm delete kiali-operator -n kiali-operator
```

- Then deploy again as usual

### In case we want to redeploy the application via `kubectl`

- Run

```bash
kubectl delete -f $DEVOPS_PROJECT_PATH/projects/aks-istio-application/k8s_manifests/shopping.yaml
kubectl delete -f $DEVOPS_PROJECT_PATH/projects/aks-istio-application/k8s_manifests/shopping-istio-gateway.yaml
```

- Then deploy again as usual
