terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# --- NEW: Data source to automatically find the latest Ubuntu 22.04 AMI ---
# This block tells Terraform to search for an AMI that matches these filters.
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # This is the official AWS Account ID for Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 22"

  # allow access on port 22
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Using -1 means "all protocols"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Monitoring server security group"
  }
}

resource "aws_instance" "Monitoring_server" {
  # --- CHANGED: Now references the AMI ID found by the data source ---
  ami = data.aws_ami.latest_ubuntu.id

  instance_type = "t2.medium"

  # --- CHANGED: Switched to the recommended 'vpc_security_group_ids' ---
  # This uses the security group's unique ID instead of its name, which is more reliable.
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  key_name = var.key_name

  tags = {
    # --- CHANGED: Corrected tag syntax from 'Name:' to '"Name" =' ---
    "Name" = var.instance_name
  }
}
