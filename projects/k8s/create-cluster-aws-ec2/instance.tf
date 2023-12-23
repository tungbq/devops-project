provider "aws" {
  region = "us-east-1"
}

module "ec2_instance" {
  source = "./modules/ec2"

  instance_name = "k8s-node"
  # Check the AMI at https://cloud-images.ubuntu.com/locator/ec2/
  ami_id = "ami-0c7217cdde317cfec"
  # instance_type  = "t2.medium"
  instance_type  = "t2.small"
  key_name       = "k8sclusteraws"
  subnet_ids     = ["subnet-058a7514ba8adbb07", "subnet-0dbcd1ac168414927", "subnet-032f5077729435858"]
  instance_count = 1

  inbound_rules = [
    {
      from_port  = 0
      to_port    = 65000
      protocol   = "TCP"
      cidr_block = "172.31.0.0/16"
    },
    {
      from_port  = 6443
      to_port    = 6443
      protocol   = "TCP"
      cidr_block = "0.0.0.0/0"
    },
    {
      from_port  = 22
      to_port    = 22
      protocol   = "TCP"
      cidr_block = "0.0.0.0/0"
    },
    {
      from_port  = 30000
      to_port    = 32768
      protocol   = "TCP"
      cidr_block = "0.0.0.0/0"
    }
  ]

  outbound_rules = [
    {
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    }
  ]
}
