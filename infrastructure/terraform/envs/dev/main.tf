module "vpc" {
  source                  = "../../modules/vpc"
  environment             = "dev"
  vpc_cidr                = "10.10.0.0/16"
  flow_logs_retention     = 14
  map_public_ip_on_launch = false
}

module "eks" {
  source                               = "../../modules/eks"
  cluster_name                         = "dev-eks"
  kubernetes_version                   = "1.29"
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnets
  vpc_cidr                             = "10.10.0.0/16"  # Pass VPC CIDR for security group restrictions
  endpoint_public_access               = false
  cluster_endpoint_public_access_cidrs = [] # Explicitly set to empty for security
  environment                          = "dev"

  # Node group tuning (use module defaults if you prefer)
  on_demand_desired_size = 2
  on_demand_min_size     = 1
  on_demand_max_size     = 3

  spot_desired_size = 1
  spot_min_size     = 0
  spot_max_size     = 4

  node_disk_size = 30

  # Security configuration
  node_security_group_egress_cidrs = ["10.10.0.0/16"] # Restrict to VPC CIDR range
}
