output "instance_id" {
  description = "ID of the instance that has been created. Can be used in SSM Start session command with `$(terraform output instance_id\\|jq -r)`"
  value       = aws_instance.instance.id
}

output "ami" {
  description = "ID of the AMI that has been selected."
  value       = data.aws_ami.this
}

output "security_group" {
  description = "The security group created for instance. Can be used to add additional rules"
  value       = aws_security_group.security_group
}

output "instance_role" {
  description = "The IAM role assigned to the instance"
  value       = aws_iam_role.role
}