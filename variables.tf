# Auto Scaling Group variables
variable "desired_capacity" {
  default     = ""
  description = "The number of Amazon EC2 instances that the Auto Scaling group attempts to maintain"
}

variable "health_check_grace_period" {
  default     = 300
  description = "The amount of time, in seconds, that Amazon EC2 Auto Scaling waits before checking the health status of an EC2 instance that has come into service"
}

variable "health_check_type" {
  default     = "EC2"
  description = "The service to use for the health checks"
}

variable "instance_type" {
  default     = "m5.2xlarge"
  description = "Specifies the instance type of the EC2 instance"
}

variable "key_name" {
  default     = ""
  description = "Provides the name of the EC2 key pair"
}

variable "max_size" {
  description = "The maximum number of Amazon EC2 instances in the Auto Scaling group"
}

variable "min_size" {
  description = "The minimum number of Amazon EC2 instances in the Auto Scaling group"
}

variable "vpc_zone_identifier" {
  default     = []
  description = "A list of subnet IDs for a virtual private cloud (VPC)"
  type        = "list"
}

# Virtual Private Cloud variables
variable "cidr_block" {
  default     = "10.0.0.0/16"
  description = "The IPv4 network range for the VPC, in CIDR notation"
}

variable "vpc_id" {
  default     = ""
  description = "The ID of the VPC"
}

# Common variables
variable "tags" {
  default     = {}
  description = "Adds or overwrites the specified tags for the specified resources"
}
