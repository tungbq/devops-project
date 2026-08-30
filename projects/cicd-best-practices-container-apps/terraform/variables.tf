variable "prefix" {
  description = "Short name prefix for every resource this project creates."
  type        = string
  default     = "cicdcademo"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "container_image" {
  description = <<-EOT
    Image the Container App starts with. Defaults to a public Microsoft
    sample image so `terraform apply` can bootstrap the environment before
    any real image exists in the registry this project creates — the
    deploy workflow takes over from there, pointing the app at a real
    build-tagged image in ACR. Avoids the chicken-and-egg problem of
    needing a pushed image before infra that creates the registry exists.
  EOT
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "github_actions_principal_object_id" {
  description = <<-EOT
    Object ID of the Azure AD application (federated/OIDC identity) GitHub
    Actions authenticates as. When set, it's granted AcrPush on the
    registry this project creates — so CI can push images without any
    stored registry password. Leave empty to skip the role assignment
    (e.g. when applying manually before the GitHub OIDC identity exists).
  EOT
  type        = string
  default     = ""
}

variable "min_replicas" {
  description = "Container App minimum replica count."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Container App maximum replica count."
  type        = number
  default     = 3
}
