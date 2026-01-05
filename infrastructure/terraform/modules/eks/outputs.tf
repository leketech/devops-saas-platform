output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_security_group.cluster_security_group.id
}

output "node_security_group_id" {
  description = "Security group ID of the node groups"
  value       = aws_security_group.node_security_group.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster_role.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the node groups"
  value       = aws_iam_role.node_role.arn
}

output "node_iam_role_name" {
  description = "IAM role name of the node groups"
  value       = aws_iam_role.node_role.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "on_demand_node_group_id" {
  description = "On-demand node group ID"
  value       = aws_eks_node_group.on_demand.id
}

output "spot_node_group_id" {
  description = "Spot node group ID"
  value       = aws_eks_node_group.spot.id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for EKS cluster"
  value       = aws_cloudwatch_log_group.cluster_logs.name
}

output "irsa_oidc_provider_thumbprint" {
  description = "Thumbprint of OIDC Provider certificate"
  value       = data.tls_certificate.cluster.certificates[0].sha1_fingerprint
}
