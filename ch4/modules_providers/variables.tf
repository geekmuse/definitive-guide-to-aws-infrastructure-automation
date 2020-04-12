variable "environment" {
  type        = string
  description = "Deployment environment (qa|stg|prod)"
  default     = "qa"
}

variable "zone_id" {
  type        = string
  description = "Route53 Zone ID"
}

variable "zone_suffix" {
  type        = string
  description = "Route53 Zone Suffix"
}

variable "acm_cert_arn" {
  type        = map(string)
  description = "ACM Cert ARN"
}
