output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for ECR access"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions role"
  value       = aws_iam_role.github_actions.name
}

# Output ARN cho External Secrets IRSA
output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets_irsa.arn
}
