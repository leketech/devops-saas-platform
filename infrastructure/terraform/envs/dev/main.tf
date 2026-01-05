module "vpc" {
  source                = "../../modules/vpc"
  environment           = "dev"
  vpc_cidr              = "10.10.0.0/16"
  flow_logs_retention   = 14
}

module "eks" {
  source              = "../../modules/eks"
  cluster_name        = "dev-eks"
  kubernetes_version  = "1.29"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  endpoint_public_access = true
  environment         = "dev"

  # Node group tuning (use module defaults if you prefer)
  on_demand_desired_size = 2
  on_demand_min_size     = 1
  on_demand_max_size     = 3

  spot_desired_size = 1
  spot_min_size     = 0
  spot_max_size     = 4

  node_disk_size = 30
}
