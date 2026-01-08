# DevOps SaaS Platform

This repository contains a complete infrastructure and application codebase for a production-ready multi-tenant SaaS platform built on AWS EKS. The platform features automated CI/CD, comprehensive monitoring, security-first design, and cost optimization.

## Architecture Overview
https://github.com/leketech/devops-saas-platform/blob/782b8b056fdb7201ef6873e65fcaa301bf8a7b37/multi-saas%20project.jpeg
The platform follows a cloud-native, microservices-based architecture with:

- **Application Layer**: Go-based multi-tenant API with JWT authentication
- **Infrastructure**: AWS EKS with managed node groups
- **Database**: RDS PostgreSQL with Multi-AZ (external to EKS)
- **Cache**: ElastiCache Redis for session and rate limiting
- **Load Balancer**: Application Load Balancer with WAF
- **CI/CD**: GitHub Actions with security scanning and ArgoCD GitOps
- **Monitoring**: Prometheus, Grafana, and Loki for observability
- **Security**: IRSA, Secrets Manager, and network policies

## Project Structure

- `api/` - Go-based multi-tenant API application
- `application/` - Core application code
- `infrastructure/terraform/` - Terraform configurations for AWS infrastructure
  - `modules/vpc/` - VPC module with private/public subnets
  - `modules/eks/` - EKS cluster module with node groups
  - `envs/dev/` - Development environment configuration
  - `envs/staging/` - Staging environment configuration
  - `envs/prod/` - Production environment configuration
- `infrastructure/kubernetes/` - Kubernetes manifests
- `infrastructure/aws/` - AWS-specific configurations
- `kubernetes/` - ArgoCD app-of-apps manifests
- `.github/workflows/` - GitHub Actions CI/CD pipelines
- `blue-green-deploy/` - Blue/green and canary deployment configurations
- `cost-controls/` - Cost optimization and budget management
- `documentation/` - Architecture and security documentation
- `runbooks/` - Operational runbooks for deployment, scaling, and outage management
- `security/` - Security configurations and policies
- `horizontal-scaling/` - Horizontal scaling configurations and load testing
- `alerts/` - Alerting and monitoring configurations
- `metrics/` - Metrics and observability configurations
- `failure-scenarios/` - Failure scenario documentation and runbooks

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment. The pipeline includes the following stages:

1. **Lint** - Validates Terraform, YAML, shell script, and Go code
2. **Unit Tests** - Runs Go unit tests and Terraform validation
3. **Docker Build** - Builds the application Docker image with multi-stage build
4. **Trivy Scan** - Performs security scanning for vulnerabilities in code and container images
5. **Push to ECR** - Pushes the Docker image to Amazon ECR (only on main branch)
6. **Deploy via ArgoCD** - GitOps deployment to EKS cluster

### Pipeline Details

The workflow in `.github/workflows/ci-cd-pipeline.yml` includes:
- Terraform formatting and validation
- Go application testing
- Docker image building with security scanning
- Vulnerability scanning with Trivy
- Image pushing to ECR with proper tagging
- Security gates to prevent deployment of vulnerable images

## Required Secrets

To use this pipeline, you need to configure the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID` - AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `AWS_ACCOUNT_ID` - AWS account ID
- `AWS_REGION` - AWS region (default: us-east-1)

Additionally, for ArgoCD deployment, you'll need:
- ArgoCD server access credentials
- EKS cluster access configuration

## Deployment Process

### Prerequisites

1. AWS account with appropriate permissions
2. EKS cluster with required components
3. ArgoCD installed in the target cluster
4. Proper AWS credentials configured
5. Docker installed for local builds
6. kubectl configured for cluster access

### Multi-Environment Deployment

The platform supports three environments:

1. **Development**: Lightweight configuration for development and testing
2. **Staging**: Medium-sized configuration for pre-production validation
3. **Production**: High-availability configuration for production workloads

Each environment has separate Terraform state files and appropriate resource sizing. Each environment includes:
- VPC with private and public subnets
- EKS cluster with on-demand and spot node groups
- RDS PostgreSQL database with appropriate sizing
- Redis ElastiCache for caching and rate limiting

### Infrastructure Deployment Steps

1. **Configure AWS Credentials**: Set up AWS credentials with appropriate permissions
   ```bash
   aws configure
   ```

2. **Infrastructure Setup**: Deploy infrastructure using Terraform
   ```bash
   # For development
   cd infrastructure/terraform/envs/dev
   terraform init
   # Provide database password securely (do not hardcode in scripts)
   terraform plan -var="db_password=$(pass show db/password)"  # Example using password manager
   terraform apply -var="db_password=$(pass show db/password)"
   
   # Alternative: Use environment variables
   export TF_VAR_db_password="$(pass show db/password)"
   terraform plan
   terraform apply
   
   # For staging
   cd ../staging
   terraform init
   terraform plan -var="db_password=$(pass show db/password)"
   terraform apply -var="db_password=$(pass show db/password)"
   
   # For production
   cd ../prod
   terraform init
   terraform plan -var="db_password=$(pass show db/password)"
   terraform apply -var="db_password=$(pass show db/password)"
   ```

3. **Configure kubectl**: Get the EKS cluster configuration
   ```bash
   aws eks --region <region> update-kubeconfig --name <cluster-name>
   ```

4. **ArgoCD Bootstrap**: Deploy ArgoCD and application manifests
   ```bash
   # Install ArgoCD
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   # Wait for ArgoCD to be ready
   kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
   
   # Deploy the app-of-apps pattern
   kubectl apply -f kubernetes/
   ```

5. **CI/CD Pipeline**: Code changes automatically trigger builds and deployments

### Application Deployment via ArgoCD

The platform uses ArgoCD for GitOps deployment with the following components:
- Application manifests in the `kubernetes/` directory
- Environment-specific overlays in `kubernetes/overlays/`
- App-of-apps pattern for centralized management

### Database Initialization

The platform provisions PostgreSQL RDS databases for each environment with:
- Secure connection parameters stored in Kubernetes secrets
- Multi-AZ configuration for staging and production
- Appropriate backup retention policies
- Database credentials managed through Terraform variables

### Monitoring and Observability Setup

After infrastructure deployment:
1. Prometheus and Grafana are deployed via Kubernetes manifests
2. Loki/Promtail for log aggregation
3. Pre-configured dashboards for application and infrastructure metrics
4. AlertManager with SLO-based alerting

### Cost Controls Implementation

The platform includes comprehensive cost controls:
- Spot instances for up to 90% compute cost savings
- Resource quotas to prevent over-provisioning
- Budget alerts via AWS Budgets
- Rightsizing with VPA for optimal resource usage

### GitOps with ArgoCD

The platform uses an App-of-Apps pattern where:
- Root application manages child applications
- Each service deployed as separate ArgoCD application
- Continuous synchronization between Git and cluster state
- Automated health assessment of deployed applications

## Security Features

- **Authentication**: JWT-based with tenant isolation
- **Infrastructure Security**: IAM Roles for Service Accounts (IRSA)
- **Network Security**: Network policies and pod security standards
- **Secrets Management**: AWS Secrets Manager
- **WAF Protection**: Web Application Firewall rules
- **Image Security**: Trivy scanning in CI/CD pipeline

## Cost Optimization

- **Spot Instances**: Up to 90% cost savings with graceful interruption handling
- **Rightsizing**: VPA and resource quotas to prevent over-provisioning
- **Budget Management**: AWS Budgets with proactive notifications
- **Horizontal Scaling**: CPU and latency-based scaling to match demand

## Monitoring and Observability

- **Metrics**: Prometheus with RED metrics (Rate, Error, Duration)
- **Visualization**: Grafana dashboards
- **Logging**: Loki for structured log aggregation
- **Alerting**: SLO-based alerts with proper escalation

## Operational Runbooks

The platform includes comprehensive runbooks for:
- Deployment procedures
- Scaling operations
- Outage response
- Rollback procedures

See the `runbooks/` directory for detailed operational procedures.

## Local Development

To build and run the application locally:

```bash
# Initialize Go modules
make init

# Run tests
make test

# Build the application
make build

# Build Docker image
make docker-build

# Run linting
make lint

# Run all checks
make check
```

## Security Guidelines

This project follows security best practices to protect sensitive information:

- 🔒 **No Hardcoded Secrets**: All sensitive values are managed through variables and secrets managers
- 🔒 **Secure Credential Handling**: Database passwords and other secrets are passed via variables at runtime
- 🔒 **Proper .gitignore**: All .tfvars and credential files are excluded from Git commits
- 🔒 **Environment Variables**: Use TF_VAR_* environment variables for sensitive inputs
- 🔒 **Secrets Management**: Integrate with AWS Secrets Manager or other vault solutions for production

⚠️ **Important**: Never commit actual passwords, API keys, or other secrets to the repository. Always use secure methods to provide these values during deployment.

## Project Readiness for Deployment

The project is fully configured and ready for deployment with the following key features:

- ✅ **Complete Infrastructure as Code**: All infrastructure components defined in Terraform modules
- ✅ **Multi-Environment Support**: Dev, staging, and production environments with appropriate sizing
- ✅ **Managed Database Service**: RDS PostgreSQL configured for each environment
- ✅ **CI/CD Pipeline**: Complete GitHub Actions workflow with security scanning
- ✅ **GitOps Deployment**: ArgoCD app-of-apps pattern for automated deployments
- ✅ **Security Controls**: IRSA, network policies, and secrets management
- ✅ **Monitoring Stack**: Prometheus, Grafana, and Loki for full observability
- ✅ **Cost Optimization**: Spot instances, resource quotas, and budget alerts
- ✅ **Operational Runbooks**: Comprehensive procedures for deployment, scaling, and incident response
- ✅ **Scalability**: Auto-scaling configured for both application pods and cluster nodes

## Usage

The pipeline will automatically trigger on pushes to the main branch and on pull requests. For manual deployments, follow the infrastructure deployment steps outlined above. After infrastructure deployment, applications are deployed via ArgoCD GitOps.
