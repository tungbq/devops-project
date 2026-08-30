variable "prefix" {
  description = "Short prefix applied to every resource name (keep it lowercase, no special chars — some Azure resources like ACR/Storage have strict naming rules even though none are used here today)."
  type        = string
  default     = "azmondemo"
}

variable "location" {
  description = "Azure region for every resource in this project."
  type        = string
  default     = "eastus"
}

variable "apim_publisher_name" {
  description = "Required by Azure API Management — shown in the developer portal, not used anywhere else in this project."
  type        = string
}

variable "apim_publisher_email" {
  description = "Required by Azure API Management — used for service notifications (e.g. certificate expiry)."
  type        = string
}

variable "dotnet_orders_api_image" {
  description = "Full image reference (registry/repo:tag) for dotnet-orders-api — push your build there first, see README '3-Deploy to Azure' step 1. No default: an unset/placeholder default here would silently deploy nothing useful."
  type        = string
}

variable "java_inventory_api_image" {
  description = "Full image reference (registry/repo:tag) for java-inventory-api — same as dotnet_orders_api_image above."
  type        = string
}
