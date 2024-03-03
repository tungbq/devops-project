# Project: Provisioning AKS Cluster using Terraform

## Prerequisite

An Azure account with an active subscription

## Authenticate to Azure

```bash
az login

az account show

az account list --query "[?user.name=='<microsoft_account_email>'].{Name:name, ID:id, Default:isDefault}" --output Table

az account set --subscription "<subscription_id_or_subscription_name>"
```

## Create a service principal

```bash
chmod +x specify-service-cred.sh

# Run the scipt with you service name and subscription ID
## your_service_principal_name: input your target Service Principal Name
## your_subscription_id: input your target Subscription ID
specify-service-cred.sh "your_service_principal_name" "your_subscription_id"
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
# NOTE: Do not commit the `./k8s_config/azurek8s` file
# I've already added the `k8s_config` folder to the .gitignore. But just for sure!
echo "$(terraform output kube_config)" > ./k8s_config/azurek8s
```

- Streamline your k8s config

```bash
chmod +x streamline_k8s_config.sh
./streamline_k8s_config.sh ./k8s_config/azurek8s
```

- Accessing your cluster

```bash
export KUBECONFIG=./k8s_config/azurek8s
kubectl get nodes
```
