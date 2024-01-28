# modules/ec2/main.tf

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub") # Change this to your public key file path
}

resource "aws_instance" "windows_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.ec2_key_pair.key_name

  # Add other instance configurations as needed

  tags = {
    Name = "Windows_Instance"
  }
}
