#CONFIG

variable "locations" {
  description = "A map of workspace name to object, where the object contains the VPC and Subnet ids to create the instance in."

  type = map(object({
    vpc_id    = string
    subnet_id = string
  }))
}

variable "associate_public_ip_address" {
  type = bool
  description = "If running in a public subnet a public IP is required in order to communicate out to AWS SSM APIs, if runnnig in private subnet public IP doesnt harm, but NAT gateway will be used to talk to AWS" 
  default = true
}

variable "instance_type" {
  default = "t3.nano"
}

locals {
  username = lower(regex(".+:(?P<username>.*)", data.aws_caller_identity.current.user_id).username)
  vpc = {
    id = var.locations[terraform.workspace].vpc_id
  }
  instance = {
    type      = "t3.nano"
    disk_size = 10
    ami = { // amazon linux 2
      eu-west-1    = "ami-096f43ef67d75e998" // Ireland
      eu-central-1 = "ami-02f9ea74050d6f812" // Frankfurt
    }
    subnet_id = var.locations[terraform.workspace].subnet_id
  }
}

# BACKEND AND PROVIDERS
terraform {
  required_version = "~>1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# MAIN TF

# Role for server
resource "aws_iam_role" "role" {
  name               = "${local.username}-${terraform.workspace}-workspace-tmp-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]
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
  instance_type               = local.instance.type
  ami                         = local.instance.ami[data.aws_region.current.name]
  user_data                   = filebase64("user_data.sh")
  iam_instance_profile        = aws_iam_instance_profile.profile.id
  subnet_id                   = local.instance.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids = [
    aws_security_group.security_group.id
  ]
  tags = {
    "Name" : "${local.username}-${terraform.workspace}-workspace-tmp-instance",
    "tf-workspace" : "${local.username}-${terraform.workspace}"
  }
  volume_tags = {}
  root_block_device {
    volume_size = local.instance.disk_size
  }
}

# Create a security group that allows access to internet to pull down yum dependencies
resource "aws_security_group" "security_group" {
  name        = "${local.username}-${terraform.workspace}-workspace-tmp-instance"
  description = "sg for the workspace instance"
  vpc_id      = local.vpc.id
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
  value = aws_instance.instance.id
}
