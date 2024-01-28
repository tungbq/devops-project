# Project: Create Windows instance on AWS using Terraform

## Overview

This project help us launch a Windows instance on AWS using Terraform

## Steps

### Navigate to the current project

Ensure you are in the terraform-aws-windows-instance project.
If not, run `cd terraform-aws-windows-instance`

### Update your own credentials

Crea file `terraform.tfvars`, by running command: `cp terraform.tfvars.sample terraform.tfvars`
Then add your public ID here (to allow RDP access from your PC).
*Tips*: Visit https://www.whatismyip.com/ to get your public IP
You can refer to `terraform.tfvars.sample` for reference.

### Terraform init

Run `terraform init`

### Terraform plan

Run `terraform plan`

### Terraform apply

Run `terraform apply`
