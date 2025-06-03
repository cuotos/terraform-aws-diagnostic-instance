terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  username = coalesce(var.override_name, lower(regex(".+[:/](?P<username>.*)", data.aws_caller_identity.current.arn).username))
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
      "name" : "al2023-ami-2023*",
      "architecture" : "x86_64"
    }
  }
  user_data = templatefile("${path.module}/user_data.sh", {
    additional_user_data = var.additional_user_data
  })
  common_tags = merge({
    "tf-workspace" : terraform.workspace
    "creator" : local.username
    "comment" : var.comment != "" ? var.comment : null
    },
  var.additional_tags)
  required_policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "random_string" "module_suffix" {
  length  = 4
  special = false
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
    for_each = !var.windows ? local.ami_filters.linux : {}

    content {
      name   = filter.key
      values = [filter.value]
    }
  }
}

resource "aws_iam_role_policy_attachment" "policies" {
  for_each = { for i, val in concat(var.additional_role_policies, local.required_policies) : i => val }

  role       = aws_iam_role.role.name
  policy_arn = each.value
}

# Role for server
resource "aws_iam_role" "role" {
  name               = "${local.username}-tmp-instance-${random_string.module_suffix.result}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["created"]
    ]
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
  user_data                   = local.user_data
  iam_instance_profile        = aws_iam_instance_profile.profile.id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids = concat(
    var.additional_security_groups,
    [aws_security_group.security_group.id]
  )
  tags = merge(
    local.common_tags,
    {
      "Name" : var.instance_name_override != null ? "${var.instance_name_override}-${random_string.module_suffix.result}" : "${local.username}-tmp-instance-${random_string.module_suffix.result}"
    }
  )
  volume_tags = {}
  root_block_device {
    volume_size = var.volume_size
  }

  lifecycle {
    ignore_changes = [
      tags["created"]
    ]
    create_before_destroy = true
  }
}

resource "aws_ec2_instance_state" "instance" {
  instance_id = aws_instance.instance.id
  state       = var.state
}

# Create a security group that allows access to internet to pull down yum dependencies
resource "aws_security_group" "security_group" {
  name        = "${local.username}-tmp-instance-${random_string.module_suffix.result}"
  description = "sg for the workspace instance"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["created"]
    ]
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
