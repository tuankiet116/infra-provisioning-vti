output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for ECR access"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions role"
  value       = aws_iam_role.github_actions.name
} 
