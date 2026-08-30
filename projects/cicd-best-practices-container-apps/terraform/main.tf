# ACR names are globally unique across all of Azure and alphanumeric-only —
# a random suffix avoids a name collision with someone else's registry.
resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# admin_enabled = false on purpose — nothing in this project authenticates
# to the registry with a shared admin password. CI pushes via its own OIDC
# identity (AcrPush, granted below); the Container App pulls via its own
# user-assigned managed identity (AcrPull, in container-app.tf).
resource "azurerm_container_registry" "main" {
  name                = "acr${var.prefix}${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "github_actions_acr_push" {
  count = var.github_actions_principal_object_id != "" ? 1 : 0

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_actions_principal_object_id
}
