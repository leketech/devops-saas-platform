variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "flow_logs_retention" {
  description = "CloudWatch Log Group retention in days"
  type        = number
  default     = 30
}

variable "map_public_ip_on_launch" {
  description = "Whether to map public IP on launch for public subnets"
  type        = bool
  default     = false  # Set to false for security
}
