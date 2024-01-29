# main.tf
provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

module "ec2_instance" {
  source        = "./modules/ec2"
  instance_type = "t2.micro"              # Change as needed
  ami           = "ami-0fa9e125394e28eef" # OpenVPN Access Server
  key_name      = var.key_name            # Specify the keyname (from terraform.tfvars)
  allowed_ip    = var.allowed_ip          # Specify the allowed IP address for RDP (from terraform.tfvars)
}
