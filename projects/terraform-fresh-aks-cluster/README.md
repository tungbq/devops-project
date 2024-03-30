# Project: Provisioning AKS Cluster using Terraform

## 1-Provision a fresh AKS cluster

### Prerequisite

- An Azure account with an active subscription
- Azure CLI installed
- Kubectl installed

### Authenticate to Azure

```bash
az login
az account show

# Replace the email by your Microsoft account email (as shown in the above command)
email="replace_by_your_email"
subscription_id=$(az account list --query "[?user.name=='$email'].{Name:name, ID:id, Default:isDefault}" | jq -r '.[].ID')
echo $subscription_id
az account set --subscription $subscription_id
```

### Create a service principal

```bash
# Run the scipt with you service name and subscription ID
## your_subscription_id: input your target Subscription ID
## your_service_principal_name: input your target Service Principal Name
./specify-service-cred.sh "your_subscription_id "your_service_principal_name"
```

### Deploy cluster with terraform

```bash
### Initialize Terraform
terraform init
### Terraform plan
terraform plan -out main.tfplan
### Terraform apply
terraform apply main.tfplan
```

### Check the result

- Verify if your AKS cluster is up and running!
- NOTE: Do not commit the `./private_k8s_config/azurek8s` file
- I've already added the `private_k8s_config` folder to the .gitignore. But just for sure!

```bash
# Check cluster
resource_group_name=$(terraform output -raw resource_group_name)
az aks list --resource-group $resource_group_name --query "[].{\"K8s cluster name\":name}" --output table
# Save config to local VM
if [ ! -d "private_k8s_config" ]; then
    mkdir private_k8s_config
fi
echo "$(terraform output kube_config)" > ./private_k8s_config/azurek8s

# Streamline your k8s config
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
➜  terraform-fresh-aks-cluster git:(issue-86) ✗ export KUBECONFIG=./private_k8s_config/azurek8s
➜  terraform-fresh-aks-cluster git:(issue-86) ✗ kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-agentpool-28459652-vmss000000   Ready    agent   12m   v1.27.9
aks-agentpool-28459652-vmss000001   Ready    agent   11m   v1.27.9
➜  terraform-fresh-aks-cluster git:(issue-86) ✗ kubectl top nodes
NAME                                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
aks-agentpool-28459652-vmss000000   118m         6%     1346Mi          29%
aks-agentpool-28459652-vmss000001   166m         8%     998Mi           21%
➜  terraform-fresh-aks-cluster git:(issue-86) ✗
```

## 2-Delete AKS resources

Once done with the demo, we can cleanup resouce to save the cost

```bash
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan
# Remove the k8s config
rm private_k8s_config
```
