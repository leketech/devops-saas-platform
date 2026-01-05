resource "aws_route53_zone" "globepay" {
  name = "globepay.space"
  comment = "Hosted zone for globepay.space (created by automation)"
  force_destroy = false
}

output "globepay_zone_id" {
  value = aws_route53_zone.globepay.zone_id
}

output "globepay_nameservers" {
  value = aws_route53_zone.globepay.name_servers
}
