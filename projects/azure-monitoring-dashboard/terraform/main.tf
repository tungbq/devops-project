resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}"
  location = var.location
}

# Single workspace, shared by Container Apps platform logs, both apps'
# OpenTelemetry traces (via workspace-based Application Insights below),
# and APIM's gateway diagnostic logs — this is what makes one Workbook able
# to query all three in the same place.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# workspace_id is set on creation and cannot be changed afterwards without
# replacing this resource (a real azurerm provider constraint) — always
# workspace-based from day one here, never left to default to the legacy
# classic (non-workspace) mode.
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
}
