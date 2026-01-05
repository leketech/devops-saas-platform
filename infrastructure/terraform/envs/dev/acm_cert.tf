resource "aws_acm_certificate" "globepay" {
  domain_name               = "globepay.space"
  subject_alternative_names = ["*.globepay.space", "api.globepay.space", "app.globepay.space"]
  validation_method         = "DNS"
  tags = {
    Name = "globepay-space-acm"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.globepay.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.globepay.zone_id
  allow_overwrite = true
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "globepay" {
  certificate_arn         = aws_acm_certificate.globepay.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.globepay.arn
}
