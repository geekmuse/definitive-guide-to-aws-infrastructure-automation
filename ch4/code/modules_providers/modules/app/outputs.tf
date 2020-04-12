output "elb_dns" {
  value = "${aws_elb.public.dns_name}"
}

output "dns" {
  value = "${aws_route53_record.elb_alias.name}"
}

output "db_endpoint" {
  value = "${aws_db_instance.db.endpoint}"
}
