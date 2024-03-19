# Project: Provisioning AKS Cluster using Terraform

## Prerequisite

An Azure account with an active subscription

## Authenticate to Azure

```bash
az login
az account show

# Replace the email by your Microsoft account email (as shown in the above command)
email="replace_by_your_email"
subscription_id=$(az account list --query "[?user.name=='$email'].{Name:name, ID:id, Default:isDefault}" | jq -r '.[].ID')
echo $subscription_id
az account set --subscription $subscription_id
```

## Create a service principal

```bash
chmod +x specify-service-cred.sh

# Run the scipt with you service name and subscription ID
## your_subscription_id: input your target Subscription ID
## your_service_principal_name: input your target Service Principal Name
./specify-service-cred.sh "your_subscription_id "your_service_principal_name"
```

## Deploy cluster

### Initialize Terraform

```bash
terraform init
```

### Terraform plan

```bash
terraform plan -out main.tfplan
```

### Terraform apply

```bash
terraform apply main.tfplan
```

## Check the result

- Verify if your AKS cluster is up and running!

```bash
resource_group_name=$(terraform output -raw resource_group_name)
az aks list --resource-group $resource_group_name --query "[].{\"K8s cluster name\":name}" --output table
# NOTE: Do not commit the `./private_k8s_config/azurek8s` file
# I've already added the `private_k8s_config` folder to the .gitignore. But just for sure!
mkdir private_k8s_config
echo "$(terraform output kube_config)" > ./private_k8s_config/azurek8s
```

- Streamline your k8s config

```bash
chmod +x streamline_k8s_config.sh
./streamline_k8s_config.sh ./private_k8s_config/azurek8s
```

- Accessing your cluster

```bash
export KUBECONFIG=./private_k8s_config/azurek8s
kubectl get nodes
kubectl top nodes
```

- You now can see the output like this, congratulations!

```bash
➜  terraform-aks-cluster git:(issue-86) ✗ export KUBECONFIG=./private_k8s_config/azurek8s
➜  terraform-aks-cluster git:(issue-86) ✗ kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-agentpool-28459652-vmss000000   Ready    agent   12m   v1.27.9
aks-agentpool-28459652-vmss000001   Ready    agent   11m   v1.27.9
➜  terraform-aks-cluster git:(issue-86) ✗ kubectl top nodes
NAME                                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
aks-agentpool-28459652-vmss000000   118m         6%     1346Mi          29%
aks-agentpool-28459652-vmss000001   166m         8%     998Mi           21%
➜  terraform-aks-cluster git:(issue-86) ✗
```

## Deploy app

Using sample app from https://github.com/Azure-Samples/aks-store-demo/blob/main/aks-store-all-in-one.yaml

```bash
kubectl create ns aks-aio-app
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-all-in-one.yaml -n aks-aio-app
```

## Check deployment

Get all resource of `aks-aio-app` namespace

```bash
kubectl get all -n aks-aio-app
```

## Check service

```bash
➜  terraform-aks-cluster git:(issue-88-deploy) ✗ kubectl get service -n aks-aio-app
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)              AGE
makeline-service   ClusterIP      10.0.214.49    <none>          3001/TCP             2m2s
mongodb            ClusterIP      10.0.62.53     <none>          27017/TCP            2m7s
order-service      ClusterIP      10.0.43.255    <none>          3000/TCP             2m4s
product-service    ClusterIP      10.0.189.194   <none>          3002/TCP             2m1s
rabbitmq           ClusterIP      10.0.150.103   <none>          5672/TCP,15672/TCP   2m5s
store-admin        LoadBalancer   10.0.73.148    xx.yy.zz.aa     80:32072/TCP         118s
store-front        LoadBalancer   10.0.9.95      xx.yy.zz.ff     80:31199/TCP         119s
```

## Access to the app

- Use the <EXTERNAL-IP> of store-front to access the frontend page
  ![](./assets/result/store-front.png)
- Use the <EXTERNAL-IP> of store-admin to access the admin page
  ![](./assets/result/store-admin.png)

## Delete AKS resources

```bash
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan
# Remove the k8s config
rm private_k8s_config
```
