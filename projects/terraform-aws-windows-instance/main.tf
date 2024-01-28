# main.tf
provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

module "ec2_instance" {
  source        = "./modules/ec2"
  instance_type = "t2.micro"              # Change as needed
  ami           = "ami-xxxxxxxxxxxxxxxxx" # Specify your Windows AMI ID
}
