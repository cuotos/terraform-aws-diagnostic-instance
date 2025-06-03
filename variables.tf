# Required

variable "vpc_id" {
  type        = string
  description = "VPC to create the test instance in"
}

variable "subnet_id" {
  type        = string
  description = "Subnet to create the instance in"
}

# Optional

variable "instance_type" {
  type        = string
  description = "AWS instance type to create"
  default     = "t3.nano"
}

variable "volume_size" {
  type        = number
  description = "Root volume size of instance"
  default     = 10
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Assign public IP to the instance."
  default     = true
}

variable "windows" {
  type        = bool
  description = "Do you want to run a Windows server?... whyyy?"
  default     = false
}

variable "ami" {
  type        = string
  description = "Specify an AMI to run, if not it will use the latest Amazon Linux, or Windows Server image."
  default     = ""
}

variable "key_name" {
  type        = string
  description = "SSH key pair to use"
  default     = ""
}

variable "additional_role_policies" {
  type        = list(string)
  description = "Additional Policies to attach to the instance in additional to SSM"
  default     = []
}

variable "additional_security_groups" {
  type        = list(string)
  description = "Addition security groups to assign to the instance"
  default     = []
}

variable "comment" {
  type        = string
  description = "Comment tag to add to all resources"
  default     = ""
}

variable "additional_tags" {
  type        = map(string)
  description = "Map of tags to add to all resources"
  default     = {}
}

variable "instance_name_override" {
  type        = string
  description = "Override the name tag provided to the instance. default: <username>-tmp-instance-<random string>"
  default     = null
}

variable "additional_user_data" {
  type        = string
  description = "Additional code to be added to the user_data.sh script"
  # default must be "" and not null as you cannot pass null into the templatefile function
  default     = ""
}

variable "override_name" {
  type        = string
  description = "Override the name of the instance that is created."
  default     = null
}

variable "state" {
  type        = string
  description = "State of the instance. Valiue values are `running`, `stopped`"
  default     = "running"

  validation {
    condition     = contains(["running", "stopped"], var.state)
    error_message = "Valid values for var: state are (running, stopped)."
  }
}