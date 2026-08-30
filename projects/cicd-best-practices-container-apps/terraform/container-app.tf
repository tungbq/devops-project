resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.prefix}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# Dedicated identity for pulling from ACR — kept separate from any identity
# the app itself might later need (e.g. Key Vault access), so a compromise
# of one doesn't automatically widen the other's blast radius.
resource "azurerm_user_assigned_identity" "acr_pull" {
  name                = "id-${var.prefix}-acrpull"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "container_app_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_pull.principal_id
}

resource "azurerm_container_app" "main" {
  name                         = "ca-${var.prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_pull.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.acr_pull.id
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name = "app"
      # Deliberately not templated off a Terraform variable that changes on
      # every deploy — see README "Why the image isn't a Terraform
      # variable": ownership of "which image is live" belongs to the
      # deploy workflow's `az containerapp update`, not to `terraform
      # apply`, so infra changes and app deploys stay two independent,
      # non-colliding operations.
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 3000
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 3000
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  lifecycle {
    # The deploy workflow updates the running image via `az containerapp
    # update` (see deploy.yml) — Terraform should not fight that on the
    # next `terraform apply` and revert a live deploy back to the
    # bootstrap placeholder image.
    ignore_changes = [template[0].container[0].image]
  }
}
