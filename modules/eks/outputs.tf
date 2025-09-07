# EKS Cluster outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster certificate authority"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = var.create_node_groups ? aws_eks_node_group.main[0].arn : null
}

output "node_group_status" {
  description = "EKS node group status"
  value       = var.create_node_groups ? aws_eks_node_group.main[0].status : null
}

# OIDC Provider outputs for External Secrets Operator
output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "EKS OIDC provider URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
