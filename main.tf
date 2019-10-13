locals {
  conditions = [
    "${element(aws_route53_record.prometheus.*.name, 0)}",
    "${module.alb.dns_name}",
    "${var.domain_name}",
  ]

  desired_capacity = "${coalesce(var.desired_capacity, var.min_size)}"
  vpc_id           = "${coalesce(var.vpc_id, module.vpc.vpc_id)}"

  vpc_zone_identifier = "${
    split(
      ",",
      coalesce(
        join(",", var.vpc_zone_identifier),
        var.key_name != "" ? join(",", module.vpc.public_subnets) : join(",", module.vpc.private_subnets)
      )
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

resource "aws_security_group" "efs" {
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 2049
    protocol    = "TCP"
    to_port     = 2049
  }

  name   = "prometheus-efs"
  vpc_id = "${local.vpc_id}"
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
    "${aws_security_group.efs.id}",
  ]

  tags_as_map = "${var.tags}"

  target_group_arns = [
    "${element(module.alb.target_group_arns, 0)}",
  ]

  user_data           = "${data.template_file.prometheus.rendered}"
  vpc_zone_identifier = "${local.vpc_zone_identifier}"
}

resource "aws_efs_file_system" "prometheus" {
  performance_mode = "${var.performance_mode}"
  tags             = "${merge(map("Name", "prometheus"), var.tags)}"
  throughput_mode  = "${var.throughput_mode}"
}

resource "aws_efs_mount_target" "prometheus" {
  file_system_id = "${aws_efs_file_system.prometheus.id}"

  security_groups = [
    "${aws_security_group.efs.id}",
  ]

  subnet_id = "${element(local.vpc_zone_identifier, count.index)}"

  count = "${length(var.vpc_zone_identifier) != 0 ? length(var.vpc_zone_identifier) : 2}"
}

resource "aws_security_group" "alb" {
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
  }

  name   = "prometheus-alb"
  vpc_id = "${local.vpc_id}"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> v3.0"

  http_tcp_listeners = [
    {
      port     = 80
      protocol = "HTTP"
    },
  ]

  http_tcp_listeners_count = 1

  https_listeners = [
    {
      certificate_arn = "${var.certificate_arn}"
      port            = 443
    },
  ]

  https_listeners_count = "${var.certificate_arn != "" ? 1 : 0}"
  load_balancer_name    = "prometheus"
  logging_enabled       = false

  security_groups = [
    "${aws_security_group.alb.id}",
  ]

  subnets = "${coalescelist(var.subnets, module.vpc.public_subnets)}"

  target_groups_defaults = {
    health_check_path = "/-/healthy"
  }

  target_groups = [
    {
      name             = "prometheus"
      backend_protocol = "HTTP"
      backend_port     = 9090
    },
  ]

  target_groups_count = 1
  vpc_id              = "${local.vpc_id}"
}

resource "aws_lb_listener_rule" "http" {
  action {
    redirect {
      host        = "${var.domain_name}"
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

    target_group_arn = "${join("", module.alb.target_group_arns)}"
    type             = "redirect"
  }

  condition {
    field  = "host-header"
    values = ["${element(local.conditions, count.index)}"]
  }

  listener_arn = "${join("", module.alb.http_tcp_listener_arns)}"

  count = "${length(local.conditions)}"
}

resource "aws_lb_listener_rule" "https" {
  action {
    redirect {
      host        = "${var.domain_name}"
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

    target_group_arn = "${join("", module.alb.target_group_arns)}"
    type             = "redirect"
  }

  condition {
    field  = "host-header"
    values = ["${aws_route53_record.prometheus.name}"]
  }

  listener_arn = "${join("", module.alb.https_listener_arns)}"
}

data "template_file" "prometheus" {
  template = "${file("${path.module}/templates/user-data.txt.tpl")}"

  vars = {
    content  = "${base64encode(file("${path.module}/files/node.yml"))}"
    dns_name = "${aws_efs_file_system.prometheus.dns_name}"
  }
}

resource "aws_route53_record" "prometheus" {
  alias {
    evaluate_target_health = true
    name                   = "${module.alb.dns_name}"
    zone_id                = "${module.alb.load_balancer_zone_id}"
  }

  name    = "${var.hosted_zone_name}"
  type    = "A"
  zone_id = "${var.hosted_zone_id}"

  count = "${var.hosted_zone_name != "" ? 1 : 0}"
}
