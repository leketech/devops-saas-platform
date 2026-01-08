# Terraform Environments

This directory contains the Terraform configurations for different environments.

## Environments

### Development (dev)
- Purpose: Development and testing
- VPC CIDR: `10.10.0.0/16`
- EKS Cluster: `dev-eks`
- Node configuration: Small, cost-efficient setup

### Staging (staging)
- Purpose: Pre-production testing and validation
- VPC CIDR: `10.20.0.0/16`
- EKS Cluster: `staging-eks`
- Node configuration: Medium-sized setup for testing

### Production (prod)
- Purpose: Production workloads
- VPC CIDR: `10.30.0.0/16`
- EKS Cluster: `prod-eks`
- Node configuration: High-availability setup for production

## Common Architecture

All environments follow the same architecture pattern:
- VPC with private and public subnets across 3 availability zones
- EKS cluster with both on-demand and spot node groups
- Private cluster endpoints (no public access)
- VPC flow logs with configurable retention
- NAT gateways for private subnet internet access

## Deployment

Each environment can be deployed independently:

```bash
# For development
cd dev
terraform init
terraform plan
terraform apply

# For staging
cd staging
terraform init
terraform plan
terraform apply

# For production
cd prod
terraform init
terraform plan
terraform apply
```

**Note**: Ensure proper AWS credentials are configured before deployment.