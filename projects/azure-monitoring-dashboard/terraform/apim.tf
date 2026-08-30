# Consumption tier: serverless, pay-per-call, provisions in ~15 min (vs.
# 30-45+ min for Developer tier) — the right choice for a demo project you
# spin up and tear down, not a production gateway. Trade-off: no VNet
# integration, no built-in caching — irrelevant here.
resource "azurerm_api_management" "main" {
  name                = "apim-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "Consumption_0"
}

# One API, path-based routing to both apps (/orders/* -> dotnet-orders-api,
# handled entirely by dotnet-orders-api's own routes since it's the only
# externally-facing app — java-inventory-api stays internal-only, called
# only by dotnet-orders-api, never directly through APIM). This mirrors a
# realistic "API gateway in front of one public service" shape rather than
# exposing an internal service through the gateway for no reason.
resource "azurerm_api_management_api" "orders" {
  name                = "orders-api"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Orders API"
  path                = "orders"
  protocols           = ["https"]
  service_url         = "https://${azurerm_container_app.dotnet_orders_api.ingress[0].fqdn}"
}

resource "azurerm_api_management_api_operation" "list_orders" {
  operation_id        = "list-orders"
  api_name            = azurerm_api_management_api.orders.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "List orders"
  method              = "GET"
  url_template        = "/api/orders"
}

resource "azurerm_api_management_api_operation" "create_order" {
  operation_id        = "create-order"
  api_name            = azurerm_api_management_api.orders.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Create order"
  method              = "POST"
  url_template        = "/api/orders"

  request {
    representation {
      content_type = "application/json"
    }
  }
}

resource "azurerm_api_management_api_operation" "health" {
  operation_id        = "health"
  api_name            = azurerm_api_management_api.orders.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Health"
  method              = "GET"
  url_template        = "/health"
}

# Sends every gateway request/response through to Application Insights —
# this is the "APIM-level" RED-metrics source the Workbook queries
# alongside each app's own OpenTelemetry data (ApiManagementGatewayLogs vs.
# AppRequests — two different views of the same traffic, useful for
# comparing "what APIM saw" against "what the app itself recorded").
resource "azurerm_api_management_logger" "app_insights" {
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  application_insights {
    instrumentation_key = azurerm_application_insights.main.instrumentation_key
  }
}

resource "azurerm_api_management_diagnostic" "app_insights" {
  identifier                = "applicationinsights"
  resource_group_name       = azurerm_resource_group.main.name
  api_management_name       = azurerm_api_management.main.name
  api_management_logger_id  = azurerm_api_management_logger.app_insights.id
  sampling_percentage       = 100
  always_log_errors         = true
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 512
  }
  frontend_response {
    body_bytes = 512
  }
  backend_request {
    body_bytes = 512
  }
  backend_response {
    body_bytes = 512
  }
}
