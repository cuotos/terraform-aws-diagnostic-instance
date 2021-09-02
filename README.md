Create a simple test ec2 instance in VPC/Subnet of your choice, with SSM enabled so you can get a shell on it without opening SSH.
This can be used to test connectivity between AWS locations.
It runs a simple [user_data.sh](user_data.sh) script that will install some common tools (docker) and login to the ECR registry of the AWS account.

The only required variables are the `locations` which is a map of the workspace name and a VPC and Subnet to create the instance in. See the [example variables file](example-vars.tfvars).
This uses Workspaces so that you can create mulitple instances and not overwrite each other.

## The _Locations var_

```
locations = {
  workspace-name = {
    vpc_id = "vpc-xxxxxx"
    subnet_id = "subnet-xxxxxx"
  }
}
```

And example workflow might look like
```
# given a variables.tfvars file with the following contents.
locations = {
  test-vpc-private-subnet = {
    vpc_id = "vpc-123456"
    subnet_id = "subnet-111"
  },
  test-vpc-public-subnet = {
    vpc_id = "vpc-123456
    subnet_id = "subnet-222"
  }
}

# create the tf workspaces
$ terraform workspace create test-vpc-private-subnet
$ terraform workspace create test-vpc-public-subnet

$ terraform workspace select test-vpc-private-subnet

# creates the instance in the first location (subnet-111)
$ terraform apply -var-file variables.tfvars 

$ terraform workspace select test-vpc-public-subnet

# this will create another instance in subnet-222, with its TF state completely independent from the first.
$ terraform apply -var-file variables.tfvars 

# cleanup
$ terraform destroy -var-file variables.tfvars
$ terraform workspace select test-vpc-private-subnet
$ terraform destroy -var-file variables.tfvars
```

## Switching Workspaces

> These are local Terraform Workspaces NOT Terraform Cloud workspaces.
> https://www.terraform.io/docs/language/state/workspaces.html

`terraform workspace list` - show the workspaces that exist. _Default_ will ALWAYS exists, if you have never changed a workspace before this is what Terraform will be using.

`terraform workspace new vpc_one` - this will create a new local workspace called "vpc_one". If you have a Location key calls "vpc_one" then its associated VPC and Subnet IDs will be used.

`terraform workspace select xxx` - switch workspaces, this will use a new local state file and not effect any others.

`terraform apply -var-file variables.tfvars`

## Connecting to a created Server

Make sure you are using the correct Workspace as the instance id is retrieved from the TF state.
`aws ssm start-session --target $(terraform output instance_id | jq -r)`

## Starting a service in an _air gapped_ private Subnet

SSM requires access to AWS APIs in order to work. This requires the server being placed in a Subnet that has outbound internet access. This can be either a public Subnet or private with a NAT-Gateway, or in a Subnet that has VPC Endpoints configured for `ssmmessages`, `ssm`, and `ec2messages`

# Terraform Docs
The following is auto created by the `terraform-docs` command. Do not edit them manually in the README.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet to create the instance in | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC to create the test instance in | `string` | n/a | yes |
| <a name="input_ami"></a> [ami](#input\_ami) | Specify an AMI to run, if not it will use the latest Amazon Linux, or Windows Server image. | `string` | `null` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Assign public IP to the instance. | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | AWS instance type to create | `string` | `"t3.nano"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair to use | `string` | `null` | no |
| <a name="input_use_windows_ami"></a> [use\_windows\_ami](#input\_use\_windows\_ami) | Do you want to run a Windows server?... whyyy? | `bool` | `false` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Root volume size of instance | `number` | `10` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | ID of the instance that has been created. Can be used in SSM Start session command with `$(terraform output instance_id|jq -r)` |
<!-- END_TF_DOCS -->