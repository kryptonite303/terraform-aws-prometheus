locals {
  desired_capacity = "${coalesce(var.desired_capacity, var.min_size)}"
  vpc_id           = "${coalesce(var.vpc_id, module.vpc.vpc_id)}"

  vpc_zone_identifier = "${
    split(
      coalesce(
        join(",", var.vpc_zone_identifier),
        var.key_name != "" ? join(",", module.vpc.public_subnets) : join(",", module.vpc.private_subnets)
      ),
      ","
    )
  }"
}

data "aws_ami" "prometheus" {
  most_recent = true
  name_regex  = "^prometheus$"
  owners      = ["self"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v1.0"

  azs                     = "${data.aws_availability_zones.available.names}"
  cidr                    = "${var.cidr_block}"
  create_vpc              = "${var.vpc_id == "" ? true : false}"
  enable_dns_hostnames    = true
  enable_nat_gateway      = true
  map_public_ip_on_launch = "${var.key_name != "" ? true : false}"
  name                    = "prometheus"

  private_subnets = [
    "10.0.0.0/24",
    "10.0.1.0/24",
  ]

  public_subnets = [
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]

  tags = "${var.tags}"
}

resource "aws_security_group" "prometheus" {
  name   = "prometheus"
  vpc_id = "${local.vpc_id}"
}

resource "aws_security_group_rule" "ingress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9090
  protocol          = "TCP"
  security_group_id = "${aws_security_group.prometheus.id}"
  to_port           = 9090
  type              = "ingress"
}

resource "aws_security_group_rule" "allow_ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "TCP"
  security_group_id = "${aws_security_group.prometheus.id}"
  to_port           = 22
  type              = "ingress"

  count = "${var.key_name != "" ? 1 : 0}"
}

resource "aws_security_group_rule" "egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.prometheus.id}"
  to_port           = 0
  type              = "egress"
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> v2.0"

  associate_public_ip_address = "${var.key_name != "" ? true : false}"
  desired_capacity            = "${local.desired_capacity}"
  health_check_type           = "${var.health_check_type}"
  health_check_grace_period   = "${var.health_check_grace_period}"
  image_id                    = "${data.aws_ami.prometheus.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  max_size                    = "${var.max_size}"
  min_size                    = "${var.min_size}"
  name                        = "prometheus"

  # If the launch configuration for the auto scaling group changes, then
  # a new auto scaling group is deployed. This strategy is similar to a
  # canary deployment.
  recreate_asg_when_lc_changes = true

  root_block_device = [
    {
      volume_size = 50
      volume_type = "gp2"
    },
  ]

  security_groups = [
    "${aws_security_group.prometheus.id}",
  ]

  tags_as_map         = "${var.tags}"
  vpc_zone_identifier = "${local.vpc_zone_identifier}"
}
