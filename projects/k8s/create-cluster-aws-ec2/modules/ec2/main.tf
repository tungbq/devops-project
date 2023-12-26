resource "aws_security_group" "instance-sg" {
  name        = "K8s Node SG"
  description = "SG for K8s Nodes"

  dynamic "ingress" {
    for_each = var.inbound_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr_block]
    }
  }

  dynamic "egress" {
    for_each = var.outbound_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = [egress.value.cidr_block]
    }
  }
}

resource "aws_instance" "k8s_nodes" {
  count = var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.instance-sg.id]

  user_data = file("${path.module}/scripts/setup_env.sh")

  tags = {
    Name = count.index == 0 ? "controlplane" : "node0${count.index}"
  }

  subnet_id = element(var.subnet_ids, count.index % length(var.subnet_ids))
}

output "public_ips" {
  value = [for instance in aws_instance.k8s_nodes : instance.public_ip]
}
