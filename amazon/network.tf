data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-security-group"
  description = "Security group for cluster platform"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # kubectl access
    description = "K3S API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  egress {
    description = "All Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-security-group"
    Component = "platform"
  }
}


resource "aws_eip" "cluster" {
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-ip"
    Component = "platform"
  }
}
