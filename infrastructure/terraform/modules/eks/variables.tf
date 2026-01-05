variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster and node groups"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
}

# On-Demand Node Group Configuration
variable "on_demand_desired_size" {
  description = "Desired number of on-demand nodes"
  type        = number
  default     = 2
}

variable "on_demand_min_size" {
  description = "Minimum number of on-demand nodes"
  type        = number
  default     = 1
}

variable "on_demand_max_size" {
  description = "Maximum number of on-demand nodes"
  type        = number
  default     = 5
}

variable "on_demand_instance_types" {
  description = "Instance types for on-demand node group"
  type        = list(string)
  default     = ["t2.micro", "t3.micro"]
}

# Spot Node Group Configuration
variable "spot_desired_size" {
  description = "Desired number of spot nodes"
  type        = number
  default     = 0
}

variable "spot_min_size" {
  description = "Minimum number of spot nodes"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum number of spot nodes"
  type        = number
  default     = 2
}

variable "spot_instance_types" {
  description = "Instance types for spot node group"
  type        = list(string)
  default     = ["t2.micro", "t3.micro"]
}

variable "node_disk_size" {
  description = "Disk size for nodes in GB"
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks to allow access to the EKS cluster endpoint when public access is enabled"
  type        = list(string)
  default     = ["10.0.0.0/8"] # Use more restrictive CIDR in production
}

variable "node_security_group_egress_cidrs" {
  description = "List of CIDR blocks for node security group egress rules"
  type        = list(string)
  default     = ["10.0.0.0/8"] # Restrict to VPC CIDR range by default
}
