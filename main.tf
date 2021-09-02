#CONFIG

variable "locations" {
  description = "A map of workspace name to object, where the object contains the VPC and Subnet ids to create the instance in."

  type = map(object({
    vpc_id    = string
    subnet_id = string
  }))
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

# MAIN TF
module "diagnostic-instance" {
  source = "./modules/instance"

  vpc_id    = var.locations[terraform.workspace].vpc_id
  subnet_id = var.locations[terraform.workspace].subnet_id
  
  additional_role_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]
}

output "instance_id" {
  value = module.diagnostic-instance.instance_id
}

output "ami_id" {
  value = module.diagnostic-instance.ami.image_id
}