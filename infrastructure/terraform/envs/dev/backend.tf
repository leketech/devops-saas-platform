terraform {
  backend "s3" {
    bucket         = "saas-terraform-state"
    key            = "eks/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}