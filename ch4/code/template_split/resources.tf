# This provides an analogue to the ${AWS::...} pseudo-variables
# in CloudFormation.
data "aws_region" "current" {}

resource "aws_security_group" "public_os_access" {
  name        = "public_os_access"
  description = "Enable public access via OS-specific port"

  ingress {
    from_port   = "${lookup(var.connect_port_by_os, var.operating_system)}"
    to_port     = "${lookup(var.connect_port_by_os, var.operating_system)}"
    protocol    = "tcp"
    cidr_blocks = ["${var.public_location}"]
  }
}

resource "aws_instance" "public_instance" {
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  ami = "${lookup(var.ami_by_region_os[data.aws_region.current.name], var.operating_system)}"
  vpc_security_group_ids = ["${aws_security_group.public_os_access.id}"]
}