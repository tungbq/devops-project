# modules/ec2/main.tf

resource "aws_instance" "windows_instance" {
  ami           = var.ami
  instance_type = var.instance_type

  # Add other instance configurations as needed

  tags = {
    Name = "Windows_Instance"
  }
}
