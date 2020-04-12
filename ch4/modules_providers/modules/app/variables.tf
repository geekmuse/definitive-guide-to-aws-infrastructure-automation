locals {
  instance_type = {
    small  = "t2.micro"
    medium = "t2.medium"
    large  = "t2.large"
  }

  db_instance_class = {
    small  = "db.t3.micro"
    medium = "db.t3.medium"
    large  = "db.t3.large"
  }

  db_storage = {
    small  = 25
    medium = 50
    large  = 100
  }

  elb_zone_id = {
    us-east-1 = "Z35SXDOTRQ7X7K"
    us-east-2 = "Z3AADJGX6KTTL2"
    us-west-2 = "Z1H1FL5HABSF5"
  }
}

variable "acm_cert_arn" {
  description = "ARN of ACM certificate"
  type        = string
}

variable "customer_type" {
  description = "Customer designation (small|medium|large)"
  type        = string
  default     = "small"
}

variable "customer_name" {
  description = "Customer name"
  type        = string
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "RDS subnet group name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "zone_id" {
  type        = string
  description = "Route53 Zone ID"
}

variable "zone_suffix" {
  type        = string
  description = "Route53 Zone Suffix"
}
