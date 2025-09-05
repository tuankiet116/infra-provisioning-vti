terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9.0"
    }
  }
  
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "github-actions-oidc-provider"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# IAM Role for Dev Environment
resource "aws_iam_role" "github_actions_dev" {
  name = "github-actions-terraform-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-terraform-dev"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# IAM Role for Prod Environment
resource "aws_iam_role" "github_actions_prod" {
  name = "github-actions-terraform-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-terraform-prod"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

# Policy for Terraform operations
resource "aws_iam_policy" "terraform_permissions" {
  name        = "terraform-permissions"
  description = "Permissions for Terraform operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 permissions
          "ec2:*",
          
          # EKS permissions
          "eks:*",
          
          # IAM permissions
          "iam:*",
          
          # ECR permissions
          "ecr:*",
          
          # VPC permissions
          "vpc:*",
          
          # S3 permissions (for state backend)
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          
          # DynamoDB permissions (for state locking)
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          
          # CloudFormation permissions
          "cloudformation:*",
          
          # Auto Scaling permissions
          "autoscaling:*",
          
          # Application Load Balancer permissions
          "elasticloadbalancing:*",
          
          # Route53 permissions
          "route53:*",
          
          # CloudWatch permissions
          "cloudwatch:*",
          "logs:*",
          
          # KMS permissions
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          
          # STS permissions
          "sts:GetCallerIdentity",
          "sts:AssumeRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.terraform_state_bucket}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.terraform_state_bucket}/*"
      }
    ]
  })

  tags = {
    Name      = "terraform-permissions"
    ManagedBy = "terraform"
  }
}

# Attach policy to Dev role
resource "aws_iam_role_policy_attachment" "github_actions_dev_policy" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = aws_iam_policy.terraform_permissions.arn
}

# Attach policy to Prod role
resource "aws_iam_role_policy_attachment" "github_actions_prod_policy" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = aws_iam_policy.terraform_permissions.arn
}

# Output the role ARNs
output "github_actions_dev_role_arn" {
  description = "ARN of the IAM role for GitHub Actions Dev environment"
  value       = aws_iam_role.github_actions_dev.arn
}

output "github_actions_prod_role_arn" {
  description = "ARN of the IAM role for GitHub Actions Prod environment"
  value       = aws_iam_role.github_actions_prod.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
