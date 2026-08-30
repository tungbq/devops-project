output "acr_login_server" {
  description = "Registry the deploy workflow pushes to and the Container App pulls from."
  value       = azurerm_container_registry.main.login_server
}

output "container_app_name" {
  description = "Name the deploy workflow passes to `az containerapp update`."
  value       = azurerm_container_app.main.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "container_app_url" {
  description = "Public URL the deploy workflow's smoke test calls after each deploy."
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "acr_pull_identity_client_id" {
  description = "Client ID of the managed identity the Container App uses to pull images (informational — not needed for CI)."
  value       = azurerm_user_assigned_identity.acr_pull.client_id
}
