module "vpc" {
  source              = "../../modules/vpc"
  environment         = "dev"
  vpc_cidr            = "10.10.0.0/16"
  flow_logs_retention = 14
}

module "rds" {
  source        = "../../modules/rds"
  environment   = "dev"
  vpc_id        = module.vpc.vpc_id
  vpc_cidr      = "10.10.0.0/16"
  subnet_ids    = module.vpc.private_subnets
  username      = "admin"
  password      = var.db_password
  instance_class = "db.t3.micro"
  storage_size   = 20
  multi_az      = false
  backup_retention = 7
  skip_final_snapshot = true
}

module "eks" {
  source                 = "../../modules/eks"
  cluster_name           = "dev-eks"
  kubernetes_version     = "1.29"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  endpoint_public_access = true
  environment            = "dev"
  db_endpoint           = module.rds.db_endpoint
  db_name               = module.rds.db_name
  db_username           = module.rds.db_username
  db_port               = module.rds.db_port
  db_password           = var.db_password

  # Node group tuning (use module defaults if you prefer)
  on_demand_desired_size = 2
  on_demand_min_size     = 1
  on_demand_max_size     = 3

  spot_desired_size = 1
  spot_min_size     = 0
  spot_max_size     = 4

  node_disk_size = 30
}
