# variables.tf
variable "allowed_ip" {
  description = "The IP address allowed for RDP access"
}

variable "key_name" {
  description = "The keyname for RDP init password retrieval"
}
