output "customer_a" {
  value = "${
    map(
      "main", map(
        "elb_dns", "${module.customer_a_main_site.elb_dns}",
        "https", "https://${module.customer_a_main_site.dns}",
        "db_endpoint", "${module.customer_a_main_site.db_endpoint}",
      ),
      "dr", map(
        "elb_dns", "${module.customer_a_dr_site.elb_dns}",
        "https", "https://${module.customer_a_dr_site.dns}",
        "db_endpoint", "${module.customer_a_dr_site.db_endpoint}",
      ),
    )
  }"
}
