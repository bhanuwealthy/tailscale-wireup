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
      tag_name = "tf-tscale-hom-gw"
    }
    "me-central-1" = {
      key_name = "gw-dxb"
      tag_name = "tf-tscale-dxb-gw"
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

data "aws_security_group" "my_launcher_sg" {
  name = "launch-wizard-1"
}

resource "aws_instance" "free_tier" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = local.region_config[var.active_region].key_name
  vpc_security_group_ids = [data.aws_security_group.my_launcher_sg.id]

  tags = {
    Name        = local.region_config[var.active_region].tag_name
    Environment = "Development"
  }

  user_data = templatefile("${path.module}/tailscale.sh.tpl", {
    TF_REGION   = local.region_config[var.active_region].tag_name
    TS_AUTH_KEY = local.ts_auth_key
  })
}
