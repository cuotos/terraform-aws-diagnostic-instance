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
`aws ssm start-session $(terraform output instance_id | jq -r)`

## Starting a service in an _air gapped_ private Subnet

SSM requires access to AWS APIs in order to work. This requires the server being placed in a Subnet that has outbound internet access. This can be either a public Subnet or private with a NAT-Gateway, or in a Subnet that has VPC Endpoints configured for `ssmmessages`, `ssm`, and `ec2messages`

# Terraform Docs
The following is auto created by the `terraform-docs` command. Do not edit them manually in the README.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.29.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.29.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | n/a | `bool` | `false` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"t3.nano"` | no |
| <a name="input_locations"></a> [locations](#input\_locations) | A map of workspace name to object, where the object contains the VPC and Subnet ids to create the instance in. | <pre>map(object({<br>    vpc_id    = string<br>    subnet_id = string<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | n/a |
<!-- END_TF_DOCS -->