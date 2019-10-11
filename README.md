## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cidr\_block | The IPv4 network range for the VPC, in CIDR notation | string | `"10.0.0.0/16"` | no |
| desired\_capacity | The number of Amazon EC2 instances that the Auto Scaling group attempts to maintain | string | `""` | no |
| health\_check\_grace\_period | The amount of time, in seconds, that Amazon EC2 Auto Scaling waits before checking the health status of an EC2 instance that has come into service | string | `"300"` | no |
| health\_check\_type | The service to use for the health checks | string | `"EC2"` | no |
| instance\_type | Specifies the instance type of the EC2 instance | string | `"m5.2xlarge"` | no |
| key\_name | Provides the name of the EC2 key pair | string | `""` | no |
| max\_size | The maximum number of Amazon EC2 instances in the Auto Scaling group | string | n/a | yes |
| min\_size | The minimum number of Amazon EC2 instances in the Auto Scaling group | string | n/a | yes |
| subnets | The IDs of the subnets | list | `<list>` | no |
| tags | Adds or overwrites the specified tags for the specified resources | map | `<map>` | no |
| vpc\_id | The ID of the VPC | string | `""` | no |
| vpc\_zone\_identifier | A list of subnet IDs for a virtual private cloud (VPC) | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| dns\_name | The public DNS name of the load balancer |