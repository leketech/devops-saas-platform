output "db_endpoint" {
  description = "Connection endpoint for the database"
  value       = aws_db_instance.postgres.endpoint
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "db_username" {
  description = "Username for the database"
  value       = aws_db_instance.postgres.username
}

output "db_port" {
  description = "Port for the database"
  value       = aws_db_instance.postgres.port
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.postgres.id
}

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.postgres.name
}