Create a simple ec2 instance in VPC/Subnet of your choice, with SSM enabled so you can get a shell on it without opening SSH.
This can be used to test connectivity between AWS locations.
It runs a simple [user_data.sh](user_data.sh) script that will install some common tools (docker) and login to the ECR registry of the AWS account.

The only required variables are the `vpc_id` and `subnet_id` where you want to creat the instance.

> The instance MUST have access to AWS Apis for SSM to work. This can be via a IGW (public IP on instance, or via VPC-Endpoints, see [Starting a service in an air gapped private Subnet](#starting-a-service-in-an-air-gapped-private-subnet))
## Connecting to a created Server

You can get the instance id from Terraform and pass it straight into AWS CLI. Note the `jq -r` which removes the quotes from the instance_id as AWS CLI fails if they are present. 

`aws ssm start-session --target $(terraform output instance_id | jq -r)`

## Starting a service in an _air gapped_ private Subnet

SSM requires access to AWS APIs in order to work. This requires the server being placed in a Subnet that has outbound internet access. This can be either a public subnet using an Internet Gateway and public IP assigned to the instance, a private subnet with a NAT-Gateway, or in a subnet that has [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) configured for `ssmmessages`, `ssm`, and `ec2messages`

# Terraform Docs

In order to populate the following Terraform documentation, run the `terraform-docs .` command.
The .terraform-docs.yml file contains the configuration to make sure if gets created in the correct way.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_string.module_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_role_policies"></a> [additional\_role\_policies](#input\_additional\_role\_policies) | Additional Policies to attach to the instance in additional to SSM | `list(string)` | `[]` | no |
| <a name="input_additional_security_groups"></a> [additional\_security\_groups](#input\_additional\_security\_groups) | Addition security groups to assign to the instance | `list(string)` | `[]` | no |
| <a name="input_ami"></a> [ami](#input\_ami) | Specify an AMI to run, if not it will use the latest Amazon Linux, or Windows Server image. | `string` | `""` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Assign public IP to the instance. | `bool` | `true` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Comment tag to add to all resources | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | AWS instance type to create | `string` | `"t3.nano"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair to use | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet to create the instance in | `string` | n/a | yes |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Root volume size of instance | `number` | `10` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC to create the test instance in | `string` | n/a | yes |
| <a name="input_windows"></a> [windows](#input\_windows) | Do you want to run a Windows server?... whyyy? | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami"></a> [ami](#output\_ami) | ID of the AMI that has been selected. |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | ID of the instance that has been created. Can be used in SSM Start session command with `$(terraform output instance_id\|jq -r)` |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | The security group created for instance. Can be used to add additional rules |
<!-- END_TF_DOCS -->