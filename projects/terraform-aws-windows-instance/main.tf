# main.tf
provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

module "ec2_instance" {
  source        = "./modules/ec2"
  instance_type = "t3.micro"              # Change as needed
  ami           = "ami-00d990e7e5ece7974" # Windows server 2022
  key_name      = var.key_name            # Specify the keyname (from terraform.tfvars)
  allowed_ip    = var.allowed_ip          # Specify the allowed IP address for RDP (from terraform.tfvars)
}
