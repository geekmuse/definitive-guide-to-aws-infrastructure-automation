output "customer_a" {
  value = "${
    map(
      "elb_dns", "${module.customer_a.elb_dns}",
      "https", "https://${module.customer_a.dns}",
      "db_endpoint", "${module.customer_a.db_endpoint}",
    )
  }"
}
