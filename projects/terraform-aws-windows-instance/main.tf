# main.tf
provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

module "ec2_instance" {
  source        = "./modules/ec2"
  instance_type = "t2.micro"              # Change as needed
  ami           = "ami-00d990e7e5ece7974" # Windows server 2022
  key_name      = "demo-window-ec2"
}
