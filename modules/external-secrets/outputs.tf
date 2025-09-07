# IAM Role outputs
output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.arn
}

output "external_secrets_role_name" {
  description = "Name of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.name
}

# AWS Secrets Manager outputs
output "backend_secret_name" {
  description = "Name of the backend secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.backend_secrets.name
}

output "backend_secret_arn" {
  description = "ARN of the backend secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.backend_secrets.arn
}

output "frontend_secret_name" {
  description = "Name of the frontend secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.frontend_secrets.name
}

output "frontend_secret_arn" {
  description = "ARN of the frontend secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.frontend_secrets.arn
}

# For Kubernetes ServiceAccount annotation
output "service_account_annotation" {
  description = "Annotation for Kubernetes ServiceAccount to assume the IAM role"
  value = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
  }
}
