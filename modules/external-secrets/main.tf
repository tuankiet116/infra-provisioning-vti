# Data sources
data "aws_caller_identity" "current" {}

# IAM Role for External Secrets Operator
resource "aws_iam_role" "external_secrets" {
  name = "${var.vti_id}-external-secrets-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:external-secrets-system:external-secrets"
            "${replace(var.eks_oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.vti_id}-external-secrets-role-${var.environment}"
    Environment = var.environment
    Component   = "external-secrets"
    ManagedBy   = "terraform"
  }
}

# IAM Policy for External Secrets Operator
resource "aws_iam_policy" "external_secrets" {
  name        = "${var.vti_id}-external-secrets-policy-${var.environment}"
  description = "Policy for External Secrets Operator to access AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.vti_id}-ecommerce-vti-*-${var.environment}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.vti_id}-external-secrets-policy-${var.environment}"
    Environment = var.environment
    Component   = "external-secrets"
    ManagedBy   = "terraform"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

# AWS Secrets Manager Secrets
resource "aws_secretsmanager_secret" "backend_secrets" {
  name        = "${var.vti_id}-ecommerce-vti-backend-${var.environment}"
  description = "Backend application secrets for ${var.environment} environment"

  recovery_window_in_days = 7

  tags = {
    Name        = "${var.vti_id}-ecommerce-vti-backend-${var.environment}"
    Environment = var.environment
    Component   = "backend"
    Project     = "ecommerce-vti"
    ManagedBy   = "terraform"
  }
}

# Frontend secrets
resource "aws_secretsmanager_secret" "frontend_secrets" {
  name        = "${var.vti_id}-ecommerce-vti-frontend-${var.environment}"
  description = "Frontend application secrets for ${var.environment} environment"

  recovery_window_in_days = 7

  tags = {
    Name        = "${var.vti_id}-ecommerce-vti-frontend-${var.environment}"
    Environment = var.environment
    Component   = "frontend"
    Project     = "ecommerce-vti"
    ManagedBy   = "terraform"
  }
}
