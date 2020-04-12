data "aws_vpc" "vpc" {
  filter {
    name = "tag:Environment"
    values = [
      "${var.environment}"
    ]
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  filter {
    name = "tag:Tier"
    values = [
      "public"
    ]
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  filter {
    name = "tag:Tier"
    values = [
      "private"
    ]
  }
}

data "aws_subnet_ids" "data" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  filter {
    name = "tag:Tier"
    values = [
      "data"
    ]
  }
}

resource "aws_db_subnet_group" "customer" {
  name        = "customer-db-subnet-group"
  description = "Customer DB subnet group"
  subnet_ids  = "${data.aws_subnet_ids.data.ids}"
}

module "customer_a" {
  source = "./modules/app"

  acm_cert_arn         = "${var.acm_cert_arn}"
  customer_type        = "small"
  customer_name        = "CustomerA"
  environment          = "${var.environment}"
  public_subnets       = "${data.aws_subnet_ids.public.ids}"
  private_subnets      = "${data.aws_subnet_ids.private.ids}"
  db_subnet_group_name = "${aws_db_subnet_group.customer.name}"
  vpc_id               = "${data.aws_vpc.vpc.id}"
  zone_id              = "${var.zone_id}"
  zone_suffix          = "${var.zone_suffix}"
}
