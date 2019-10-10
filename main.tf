data "aws_ami" "prometheus" {
  most_recent = true
  name_regex  = "^prometheus$"
  owners      = ["self"]
}
