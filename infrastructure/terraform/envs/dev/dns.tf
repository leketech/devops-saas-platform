# Route53 Hosted Zone for the SaaS platform
resource "aws_route53_zone" "main" {
  name = "saas-platform.local"

  tags = {
    Name        = "saas-platform-zone"
    Environment = "dev"
  }
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_nameservers" {
  description = "Route53 Nameservers"
  value       = aws_route53_zone.main.name_servers
}

output "route53_zone_name" {
  description = "Route53 Zone Name"
  value       = aws_route53_zone.main.name
}
