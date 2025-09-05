# Outputs for GitHub Actions
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for this environment"
  value       = module.iam.github_actions_role_arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}
