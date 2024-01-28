# modules/ec2/main.tf

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow RDP access from a specific IP address"

  # Only allow inbound RDP access from specific IP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}/32"]
  }

  # Allow the instance to connect to the world
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add other security group configurations as needed
}

resource "aws_instance" "windows_instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  # Add other instance configurations as needed

  tags = {
    Name = "Windows_Instance"
  }
}
