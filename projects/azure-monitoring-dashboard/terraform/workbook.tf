# NOTE: the correct resource name is azurerm_application_insights_workbook
# — azurerm_dashboard_workbook does not exist in the provider (verified
# against the Terraform Registry docs; an earlier draft of this file used
# the wrong name).
#
# `name` must be a valid GUID (verified against the provider docs — a
# friendly string like "slo-dashboard" is rejected) — `random_uuid`
# generates one once and keeps it stable across applies. The human-readable
# name goes in `display_name` instead, which has no such restriction.
resource "random_uuid" "slo_dashboard" {}

resource "azurerm_application_insights_workbook" "slo_dashboard" {
  name                = random_uuid.slo_dashboard.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  display_name        = "Service health — SLO, RED metrics, root-cause search"
  category            = "workbook"

  # source_id must not contain uppercase letters — a real, documented
  # azurerm provider validation quirk (Terraform resource IDs otherwise
  # preserve the case you typed for the resource group/name).
  source_id = lower(azurerm_log_analytics_workspace.main.id)

  data_json = file("${path.module}/../workbook/slo-dashboard.workbook.json")
}
