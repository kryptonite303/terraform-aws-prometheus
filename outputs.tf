output "ami" {
  value = "${data.aws_ami.prometheus.id}"
}
