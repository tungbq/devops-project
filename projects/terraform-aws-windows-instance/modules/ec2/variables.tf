#TODO
variable "instance_type" {
  description = "The type of EC2 instance"
}

variable "ami" {
  description = "The AMI ID for the Windows instance"
}

variable "key_name" {
  description = "The key name for AWS EC2 instance"
}

variable "allowed_ip" {
  description = "The IP address allowed for RDP access"
}
