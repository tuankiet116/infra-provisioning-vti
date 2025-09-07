# ===== TERRAFORM ADMIN ROLE OUTPUTS =====
output "terraform_admin_role_arn" {
  description = "ARN of the Terraform Admin role for infrastructure management"
  value       = aws_iam_role.terraform_admin.arn
}

output "terraform_admin_role_name" {
  description = "Name of the Terraform Admin role"
  value       = aws_iam_role.terraform_admin.name
}

# ===== APPLICATION DEPLOY ROLE OUTPUTS =====
output "github_actions_deploy_role_arn" {
  description = "ARN of the GitHub Actions Deploy role for application deployment"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_deploy_role_name" {
  description = "Name of the GitHub Actions Deploy role"
  value       = aws_iam_role.github_actions_deploy.name
}

# ===== EXTERNAL SECRETS IRSA ROLE OUTPUTS =====
output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets_irsa.arn
}

# ===== BACKWARD COMPATIBILITY (deprecated) =====
output "github_actions_role_arn" {
  description = "[DEPRECATED] Use github_actions_deploy_role_arn instead"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_role_name" {
  description = "[DEPRECATED] Use github_actions_deploy_role_name instead"
  value       = aws_iam_role.github_actions_deploy.name
}
