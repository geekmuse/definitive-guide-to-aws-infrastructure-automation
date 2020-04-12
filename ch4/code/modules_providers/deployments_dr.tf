data "aws_vpc" "vpc_dr" {
  provider = "aws.usw2"
  filter {
    name = "tag:Environment"
    values = [
      "${var.environment}"
    ]
  }
}

data "aws_subnet_ids" "public_dr" {
  vpc_id   = "${data.aws_vpc.vpc_dr.id}"
  provider = "aws.usw2"

  filter {
    name = "tag:Tier"
    values = [
      "public"
    ]
  }
}

data "aws_subnet_ids" "private_dr" {
  vpc_id   = "${data.aws_vpc.vpc_dr.id}"
  provider = "aws.usw2"

  filter {
    name = "tag:Tier"
    values = [
      "private"
    ]
  }
}

data "aws_subnet_ids" "data_dr" {
  vpc_id   = "${data.aws_vpc.vpc_dr.id}"
  provider = "aws.usw2"

  filter {
    name = "tag:Tier"
    values = [
      "data"
    ]
  }
}

resource "aws_db_subnet_group" "customer_dr" {
  provider    = "aws.usw2"
  name        = "customer-db-subnet-group"
  description = "Customer DB subnet group"
  subnet_ids  = "${data.aws_subnet_ids.data_dr.ids}"
}

module "customer_a_dr_site" {
  source = "./modules/dr"
  providers = {
    aws = "aws.usw2"
  }

  acm_cert_arn         = "${var.acm_cert_arn["dr"]}"
  customer_type        = "small"
  customer_name        = "CustomerA"
  environment          = "${var.environment}"
  public_subnets       = "${data.aws_subnet_ids.public_dr.ids}"
  private_subnets      = "${data.aws_subnet_ids.private_dr.ids}"
  db_subnet_group_name = "${aws_db_subnet_group.customer_dr.name}"
  vpc_id               = "${data.aws_vpc.vpc_dr.id}"
  zone_id              = "${var.zone_id}"
  zone_suffix          = "${var.zone_suffix}"
}
