variable "aws_region" {
  description = "AWS region for dev"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Database password for the application"
  type        = string
  sensitive   = true
}
