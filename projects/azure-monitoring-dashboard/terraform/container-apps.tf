resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# java-inventory-api — internal only. Nothing outside the Container Apps
# Environment calls it directly; APIM and dotnet-orders-api both reach it
# through its internal ingress FQDN (external_enabled = false still gets a
# resolvable in-environment FQDN, it's just not internet-routable).
resource "azurerm_container_app" "java_inventory_api" {
  name                         = "java-inventory-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  # `secret` is a top-level block on this resource, not nested under
  # `template` — confirmed against the actual installed provider schema
  # (`terraform providers schema -json`), not just docs prose.
  secret {
    name  = "appinsights-connection-string"
    value = azurerm_application_insights.main.connection_string
  }

  template {
    container {
      # Replace with your own registry/image once you've pushed one — see
      # README "3-Deploy to Azure" step 1. A public placeholder here would
      # just be wrong the moment someone actually applies this.
      name   = "java-inventory-api"
      image  = var.java_inventory_api_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8081
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# dotnet-orders-api — the only externally-exposed app; APIM sits in front
# of this (see apim.tf), matching how the sample microservices-orchestration
# project also keeps only the "front door" service publicly reachable.
resource "azurerm_container_app" "dotnet_orders_api" {
  name                         = "dotnet-orders-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  secret {
    name  = "appinsights-connection-string"
    value = azurerm_application_insights.main.connection_string
  }

  template {
    container {
      name   = "dotnet-orders-api"
      image  = var.dotnet_orders_api_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
      env {
        # Container Apps' internal DNS resolves other apps in the same
        # environment by name — same "config, not code" pattern as the
        # microservices-orchestration project's K8s ConfigMap, just
        # Container-Apps-flavored.
        name  = "INVENTORY_URL"
        value = "http://${azurerm_container_app.java_inventory_api.name}"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
