# ===== IAM ROLE OUTPUTS =====
# Terraform Admin Role (for infrastructure management)
output "terraform_admin_role_arn" {
  description = "ARN of the Terraform Admin role for infrastructure management"
  value       = module.iam.terraform_admin_role_arn
}

# GitHub Actions Deploy Role (for application deployment)
output "github_actions_deploy_role_arn" {
  description = "ARN of the GitHub Actions Deploy role for application deployment"
  value       = module.iam.github_actions_deploy_role_arn
}

# External Secrets IRSA Role
output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = module.iam.external_secrets_role_arn
}

# Backward compatibility (deprecated)
output "github_actions_role_arn" {
  description = "[DEPRECATED] Use github_actions_deploy_role_arn instead"
  value       = module.iam.github_actions_deploy_role_arn
}

# ===== INFRASTRUCTURE OUTPUTS =====

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

# External Secrets outputs
output "backend_secret_name" {
  description = "Name of the backend secrets in AWS Secrets Manager"
  value       = module.external_secrets.backend_secret_name
}

output "frontend_secret_name" {
  description = "Name of the frontend secrets in AWS Secrets Manager"
  value       = module.external_secrets.frontend_secret_name
}
