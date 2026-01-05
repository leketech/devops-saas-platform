# DevOps SaaS Platform

This repository contains infrastructure as code for a SaaS platform, including Terraform configurations for AWS resources and Kubernetes manifests.

## Project Structure

- `infrastructure/terraform/` - Terraform configurations for AWS infrastructure
- `infrastructure/kubernetes/` - Kubernetes manifests
- `infrastructure/aws/` - AWS-specific configurations
- `.github/workflows/` - GitHub Actions CI/CD pipelines

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment. The pipeline includes the following stages:

1. **Lint** - Validates Terraform, YAML, and shell script code
2. **Unit Tests** - Runs Terraform validation and any custom tests
3. **Docker Build** - Builds the application Docker image
4. **Trivy Scan** - Performs security scanning for vulnerabilities
5. **Push to ECR** - Pushes the Docker image to Amazon ECR (only on main branch)

## Required Secrets

To use this pipeline, you need to configure the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID` - AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `AWS_ACCOUNT_ID` - AWS account ID
- `AWS_REGION` - AWS region (default: us-east-1)

## Usage

The pipeline will automatically trigger on pushes to the main branch and on pull requests.
