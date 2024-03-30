# Project: Provisioning AKS Cluster using Terraform

## Prerequisite

An Azure account with an active subscription

## 1-Provision a fresh AKS cluster

- Provision a fresh AKS cluster by following [terraform-fresh-aks-cluster](../terraform-fresh-aks-cluster/)

## 2-Deploy the sample application on AKS cluster

### Deploy with kubectl

Using sample app from https://github.com/Azure-Samples/aks-store-demo/blob/main/aks-store-all-in-one.yaml

```bash
kubectl create ns aks-aio-app
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-all-in-one.yaml -n aks-aio-app
```

### Check deployment

Get all resource of `aks-aio-app` namespace

```bash
kubectl get all -n aks-aio-app
```

### Check service

```bash
➜  terraform-fresh-aks-cluster git:(issue-88-deploy) ✗ kubectl get service -n aks-aio-app
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)              AGE
makeline-service   ClusterIP      10.0.214.49    <none>          3001/TCP             2m2s
mongodb            ClusterIP      10.0.62.53     <none>          27017/TCP            2m7s
order-service      ClusterIP      10.0.43.255    <none>          3000/TCP             2m4s
product-service    ClusterIP      10.0.189.194   <none>          3002/TCP             2m1s
rabbitmq           ClusterIP      10.0.150.103   <none>          5672/TCP,15672/TCP   2m5s
store-admin        LoadBalancer   10.0.73.148    xx.yy.zz.aa     80:32072/TCP         118s
store-front        LoadBalancer   10.0.9.95      xx.yy.zz.ff     80:31199/TCP         119s
```

### Access to the app

- Use the `EXTERNAL-IP` of store-front to access the frontend page
  ![](./assets/result/store-front.png)
- Use the `EXTERNAL-IP` of store-admin to access the admin page
  ![](./assets/result/store-admin.png)

## 3-Monitor the App with Prometheus and Grafana

### Prerequesite

- Helm

### Deploy Prometheus/Grafana stack

```bash
# Prepare
kubectl create ns monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# Deploy
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring
```

### Check deployment resource

- Check the deployment resources

```bash
# Pod checking
kubectl --namespace monitoring get pods -l "release=kube-prometheus-stack"
# All resources checking
kubectl --namespace monitoring get all
```

- Check service

```bash
➜  terraform-fresh-aks-cluster kubectl --namespace monitoring get svc

NAME                                             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                            ClusterIP   None           <none>        9093/TCP,9094/TCP,9094/UDP   3m12s
kube-prometheus-stack-alertmanager               ClusterIP   10.0.130.140   <none>        9093/TCP,8080/TCP            3m18s
kube-prometheus-stack-grafana                    ClusterIP   10.0.223.108   <none>        80/TCP                       3m18s
kube-prometheus-stack-kube-state-metrics         ClusterIP   10.0.190.136   <none>        8080/TCP                     3m18s
kube-prometheus-stack-operator                   ClusterIP   10.0.153.232   <none>        443/TCP                      3m18s
kube-prometheus-stack-prometheus                 ClusterIP   10.0.22.103    <none>        9090/TCP,8080/TCP            3m18s
kube-prometheus-stack-prometheus-node-exporter   ClusterIP   10.0.146.164   <none>        9100/TCP                     3m18s
prometheus-operated                              ClusterIP   None           <none>        9090/TCP                     3m12s
```

### Access the dashboard

- Expose Grafana

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 4000:80
```

- Expose Prometheus

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 4001:9090
```

Now we can login to http://localhost:4000 (The default username/password for Grafana is `admin/prom-operator`)

### Explore the dashboard

- Choosing the dashboard
  ![](./assets/result/grafana_dashboard_choose.png)

- View resource monitoring
  ![](./assets/result/grafana_dashboard_detail.png)

## 4-Delete AKS resources

- Once done, destroy the cluster to free up resource and avoid upcomming Azure cost ($$$)
- Follow the `Delete AKS resources` section of project [terraform-fresh-aks-cluster](../terraform-fresh-aks-cluster/)
