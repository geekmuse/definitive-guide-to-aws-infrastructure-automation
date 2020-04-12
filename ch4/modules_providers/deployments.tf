data "aws_vpc" "vpc_main" {
  provider = "aws.use1"

  filter {
    name = "tag:Environment"
    values = [
      "${var.environment}"
    ]
  }
}

data "aws_subnet_ids" "public_main" {
  vpc_id   = "${data.aws_vpc.vpc_main.id}"
  provider = "aws.use1"

  filter {
    name = "tag:Tier"
    values = [
      "public"
    ]
  }
}

data "aws_subnet_ids" "private_main" {
  vpc_id   = "${data.aws_vpc.vpc_main.id}"
  provider = "aws.use1"

  filter {
    name = "tag:Tier"
    values = [
      "private"
    ]
  }
}

data "aws_subnet_ids" "data_main" {
  vpc_id   = "${data.aws_vpc.vpc_main.id}"
  provider = "aws.use1"

  filter {
    name = "tag:Tier"
    values = [
      "data"
    ]
  }
}

resource "aws_db_subnet_group" "customer_main" {
  provider    = "aws.use1"
  name        = "customer-db-subnet-group"
  description = "Customer DB subnet group"
  subnet_ids  = "${data.aws_subnet_ids.data_main.ids}"
}

module "customer_a_main_site" {
  source = "./modules/app"
  providers = {
    aws = "aws.use1"
  }

  acm_cert_arn         = "${lookup(var.acm_cert_arn, "main")}"
  customer_type        = "small"
  customer_name        = "CustomerA"
  environment          = "${var.environment}"
  public_subnets       = "${data.aws_subnet_ids.public_main.ids}"
  private_subnets      = "${data.aws_subnet_ids.private_main.ids}"
  db_subnet_group_name = "${aws_db_subnet_group.customer_main.name}"
  vpc_id               = "${data.aws_vpc.vpc_main.id}"
  zone_id              = "${var.zone_id}"
  zone_suffix          = "${var.zone_suffix}"
}

