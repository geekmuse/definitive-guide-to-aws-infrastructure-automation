provider "aws" {}

variable "threshold_percentage" {
  type = "string"
  description = "Percentage (integer) over which alarm is triggered"
}

resource "aws_cloudwatch_metric_alarm" "infrabook" {
  alarm_name                = "aws-infrabook-ec2"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "${var.threshold_percentage}"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []
}