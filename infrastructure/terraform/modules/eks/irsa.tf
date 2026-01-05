# Module for creating IRSA roles (IAM Roles for Service Accounts)
# This can be used to create fine-grained IAM roles for Kubernetes service accounts

output "irsa_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# Helper locals for IRSA role creation
locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.cluster.arn
  oidc_provider_url = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  account_id        = data.aws_caller_identity.current.account_id
  region            = data.aws_region.current.name
}
