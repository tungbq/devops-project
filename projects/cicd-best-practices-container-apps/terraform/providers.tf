terraform {
  required_version = ">=1.5"

  # Partial config on purpose — populated at `terraform init` time via
  # `-backend-config` flags in deploy.yml (see README "One-time state
  # backend bootstrap"). Keeps a real, shared, lockable remote state
  # instead of relying on the GitHub Actions runner's local disk, which
  # is wiped after every job.
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}

  # No client secret anywhere — deploy.yml authenticates via GitHub's OIDC
  # token exchange (ARM_CLIENT_ID/ARM_TENANT_ID/ARM_SUBSCRIPTION_ID env vars
  # + the job's own id-token, per azurerm's native GitHub Actions OIDC
  # support). use_oidc is explicit here rather than left implicit so this
  # file is self-documenting about how auth works.
  use_oidc = true
}
