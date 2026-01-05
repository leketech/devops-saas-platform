output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnets_cidr" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnets_cidr" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "availability_zones" {
  description = "Availability zones used"
  value       = data.aws_availability_zones.available.names
}

output "flow_logs_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}
