output "apim_gateway_url" {
  description = "Base URL to call the orders API through APIM, e.g. {this}/orders/api/orders"
  value       = azurerm_api_management.main.gateway_url
}

output "dotnet_orders_api_url" {
  description = "Direct public URL for dotnet-orders-api (bypassing APIM) — useful for confirming the app itself is healthy before debugging APIM routing."
  value       = "https://${azurerm_container_app.dotnet_orders_api.ingress[0].fqdn}"
}

output "application_insights_connection_string" {
  description = "Connection string both sample apps read from APPLICATIONINSIGHTS_CONNECTION_STRING."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the shared workspace — every KQL query in the Workbook runs against this."
  value       = azurerm_log_analytics_workspace.main.id
}

output "workbook_resource_id" {
  description = "Resource ID of the deployed Workbook — open it via 'az monitor app-insights ...' or just find it under Azure Monitor > Workbooks in the Portal."
  value       = azurerm_application_insights_workbook.slo_dashboard.id
}
