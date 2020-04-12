data "aws_region" "current" {}

resource "aws_security_group" "public" {
  name        = "${var.customer_name}-public"
  description = "Allow inbound web traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.customer_name}-public"
    Customer    = "${var.customer_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.customer_name}-app"
  description = "Allow traffic from ELB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.public.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.customer_name}-app"
    Customer    = "${var.customer_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "data" {
  name        = "${var.customer_name}-data"
  description = "Allow inbound data traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.app.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.customer_name}-data"
    Customer    = "${var.customer_name}"
    Environment = "${var.environment}"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                    = "${data.aws_ami.amazon-linux-2.id}"
  instance_type          = "${lookup(local.instance_type, var.customer_type)}"
  vpc_security_group_ids = ["${aws_security_group.app.id}"]
  subnet_id              = "${element(var.private_subnets, 1)}"
  user_data              = "${file("${path.module}/userdata.sh")}"

  tags = {
    Name        = "${var.customer_name}-app"
    Designation = "${var.customer_type}"
    Customer    = "${var.customer_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_elb" "public" {
  name            = "${lower(var.customer_name)}-elb"
  subnets         = "${var.public_subnets}"
  security_groups = ["${aws_security_group.public.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.acm_cert_arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.app.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name        = "${lower(var.customer_name)}-elb"
    Customer    = "${var.customer_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_db_instance" "db" {
  depends_on             = ["aws_security_group.data"]
  identifier             = "${lower(var.customer_name)}"
  allocated_storage      = "${lookup(local.db_storage, var.customer_type)}"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "${lookup(local.db_instance_class, var.customer_type)}"
  name                   = "AppDb"
  username               = "admin"
  password               = "changeme123"
  vpc_security_group_ids = ["${aws_security_group.data.id}"]
  db_subnet_group_name   = "${var.db_subnet_group_name}"
  skip_final_snapshot    = true

  tags = {
    Name        = "${var.customer_name}-db"
    Designation = "${var.customer_type}"
    Customer    = "${var.customer_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "elb_alias" {
  zone_id = "${var.zone_id}"
  name    = "${lower(var.customer_name)}.${var.zone_suffix}"
  type    = "A"

  alias {
    name                   = "${aws_elb.public.dns_name}"
    zone_id                = "${lookup(local.elb_zone_id, data.aws_region.current.name)}"
    evaluate_target_health = false
  }
}
