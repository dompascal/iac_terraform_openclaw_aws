terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "openclaw_sg" {
  name        = "openclaw-tailscale-sg"
  description = "Security group for OpenClaw with Tailscale"
  vpc_id      = var.vpc_id

  # SSH access (optional, can be removed if only using Tailscale)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
    description = "SSH access"
  }

  # Tailscale UDP port
  ingress {
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tailscale"
  }

  # OpenClaw API port (adjust based on your setup)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenClaw API"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "openclaw-tailscale-sg"
  }
}

# IAM Role for EC2 (optional, for AWS services access)
resource "aws_iam_role" "openclaw_role" {
  name = "openclaw-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "openclaw-ec2-role"
  }
}

resource "aws_iam_instance_profile" "openclaw_profile" {
  name = "openclaw-instance-profile"
  role = aws_iam_role.openclaw_role.name
}

# EC2 Instance
resource "aws_instance" "openclaw" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.openclaw_sg.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.openclaw_profile.name

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    tailscale_auth_key     = var.tailscale_auth_key
    openclaw_config        = var.openclaw_config
    openclaw_gateway_token = var.openclaw_gateway_token
    moonshot_api_key       = var.moonshot_api_key
    moonshot_model         = var.moonshot_model
  })

  tags = {
    Name = "openclaw-tailscale-instance"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Elastic IP (optional)
resource "aws_eip" "openclaw_eip" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.openclaw.id
  domain   = "vpc"

  tags = {
    Name = "openclaw-eip"
  }
}
