terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  username = lower(regex(".+:(?P<username>.*)", data.aws_caller_identity.current.user_id).username)
  ami_filters = {
    common = {
      "root-device-type" : "ebs",
      "virtualization-type" : "hvm"
    }
    windows = {
      "platform" : "windows",
      "name" : "Windows_Server-2019-English-Full-Base*"
    }
    linux = {
      "name" : "amzn2-ami-hvm-2.0*"
    }
  }
}

data "aws_ami" "this" {
  owners      = ["amazon"]
  most_recent = "true"

  # common filters
  dynamic "filter" {
    for_each = local.ami_filters.common

    content {
      name   = filter.key
      values = [filter.value]
    }
  }

  # windows
  dynamic "filter" {
    for_each = var.windows ? local.ami_filters.windows : {}

    content {
      name   = filter.key
      values = [filter.value]
    }
  }

  # linux
  dynamic "filter" {
    for_each = ! var.windows ? local.ami_filters.linux : {}

    content {
      name   = filter.key
      values = [filter.value]
    }
  }
}

# Role for server
resource "aws_iam_role" "role" {
  name               = "${local.username}-${terraform.workspace}-workspace-tmp-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = concat(
    [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ],
    var.additional_role_policies
  )
  tags = {
    "tf-workspace" : "${local.username}-${terraform.workspace}"
  }
}

# Link Role to an Instance Profile (this is how the role is passed to a server)
resource "aws_iam_instance_profile" "profile" {
  role = aws_iam_role.role.name
}

# Create the EC2 compute server
resource "aws_instance" "instance" {
  key_name                    = var.key_name != "" ? var.key_name : null
  instance_type               = var.instance_type
  ami                         = var.ami != "" ? var.ami : data.aws_ami.this.image_id
  user_data                   = filebase64("${path.module}/user_data.sh")
  iam_instance_profile        = aws_iam_instance_profile.profile.id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids = concat(
    var.additional_security_groups,
    [aws_security_group.security_group.id]
  )
  tags = {
    "Name" : "${local.username}-${terraform.workspace}-workspace-tmp-instance",
    "tf-workspace" : "${local.username}-${terraform.workspace}"
  }
  volume_tags = {}
  root_block_device {
    volume_size = var.volume_size
  }
}

# Create a security group that allows access to internet to pull down yum dependencies
resource "aws_security_group" "security_group" {
  name        = "${local.username}-${terraform.workspace}-workspace-tmp-instance"
  description = "sg for the workspace instance"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = {
    "tf-workspace" : "${local.username}-${terraform.workspace}"
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

output "instance_id" {
  description = "ID of the instance that has been created. Can be used in SSM Start session command with `$(terraform output instance_id\\|jq -r)`"
  value       = aws_instance.instance.id
}

output "ami" {
  description = "ID of the AMI that has been selected."
  value       = data.aws_ami.this
}