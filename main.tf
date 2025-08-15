# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

variable "active_region" {
  type        = string
  description = "Region to deploy to"
  default     = "ap-south-2"
}

locals {
  ts_auth_key = ""
  region_config = {
    "ap-south-2" = {
      key_name = "tf-key"
      tag_name = "tf-ts-hom-gw"
    }
    "me-central-1" = {
      key_name = "gw-dxb"
      tag_name = "tf-ts-dxb-gw"
    }
  }
}

provider "aws" {
  region  = var.active_region
  profile = "home"
}

# Get the latest free Tier eligible Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


resource "aws_security_group" "ssh_access" {
  name        = "ssh-access-sg"
  description = "Security group allowing SSH and all outbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-access-sg"
  }
}

resource "aws_instance" "free_tier" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = local.region_config[var.active_region].key_name
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  tags = {
    Name        = local.region_config[var.active_region].tag_name
    Environment = "Development"
  }

  user_data = templatefile("${path.module}/tailscale.sh.tpl", {
    TF_REGION   = local.region_config[var.active_region].tag_name
    TS_AUTH_KEY = local.ts_auth_key
  })
}
