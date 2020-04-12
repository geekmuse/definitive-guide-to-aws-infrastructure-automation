output "instance_id" {
  value = "${aws_instance.public_instance.id}"
}

output "az" {
  value = "${aws_instance.public_instance.availability_zone}"
}

output "public_dns" {
  value = "${aws_instance.public_instance.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.public_instance.public_ip}"
}