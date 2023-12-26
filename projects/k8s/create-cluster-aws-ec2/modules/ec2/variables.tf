variable "instance_name" {
  type    = string
  default = "live-test-instance"
}

variable "ami_id" {
  type    = string
  default = "ami-0735c191cf914754d"
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "key_name" {
  type    = string
  default = "k8sclusteraws"
}

variable "security_group_ids" {
  type    = list(string)
  default = ["sg-01ce819e8d65269f0"]
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-058a7514ba8adbb07", "subnet-0dbcd1ac168414927", "subnet-032f5077729435858"]
}

variable "inbound_rules" {
  type = list(object({
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      from_port  = 80
      to_port    = 80
      protocol   = "TCP"
      cidr_block = "0.0.0.0/0"
    }
  ]
}

variable "outbound_rules" {
  type = list(object({
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = string
  }))
  default = [
    {
      from_port  = 32768
      to_port    = 61000
      protocol   = "tcp"
      cidr_block = "10.2.20.0/22"
    }
  ]
}
