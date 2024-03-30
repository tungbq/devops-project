# Project: Create k8s cluster on EC2 instance using terraform

This project help us practice k8s/terraform/aws

## Overview

### Introduction

- Tech stack: `k8s`, `aws`, `shell`, `terraform`
- To get basic concept of these tools, you could visit: [**devops-basic**](https://github.com/tungbq/devops-basic) repository

### Prerequisite

- Tools: `terraform`, `kubectl`, `awscli`

## 1-Create your own keypair

- For example `k8sclusteraws`

## 2-Download keypair to your local PC

- Using the .pem
- Remember to note the key path

## 3-Update the private_key_path variable

- Change this [file](./variables.tf)

## 4-Provision cluster with terraform

Remember to select 'yes' after checking all the information

```bash
## Init
terraform init
## Plan
terraform plan
## Apply
terraform apply
```

## 5-Troubleshooting

- See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
