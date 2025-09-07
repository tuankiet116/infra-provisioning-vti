# Data source để lấy OIDC provider đã tạo từ shared-resources
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ===== INFRASTRUCTURE ADMIN ROLE =====
# Role có quyền cao để quản lý IAM và infrastructure
resource "aws_iam_role" "terraform_admin" {
  name = "${var.vti_id}-${var.environment}-terraform-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = concat(
              ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/master"],
              ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"],
              [for repo in var.additional_trusted_repos : "repo:${var.github_org}/${repo}:*"],
              [for branch in var.additional_trusted_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"]
            )
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.vti_id}-${var.environment}-terraform-admin"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "infrastructure-management"
  }
}

# ===== APPLICATION DEPLOY ROLE =====
# Role chỉ có quyền deploy ứng dụng (ECR, EKS deployment)
resource "aws_iam_role" "github_actions_deploy" {
  name = "${var.vti_id}-${var.environment}-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = concat(
              ["repo:${var.github_org}/${var.github_repo}:*"],
              [for repo in var.additional_trusted_repos : "repo:${var.github_org}/${repo}:*"]
            )
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.vti_id}-${var.environment}-github-actions-deploy"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "application-deployment"
  }
}

# ===== TERRAFORM ADMIN ROLE PERMISSIONS =====
# IAM permissions for infrastructure management
resource "aws_iam_role_policy_attachment" "terraform_admin_iam" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# VPC permissions for infrastructure management
resource "aws_iam_role_policy_attachment" "terraform_admin_vpc" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# EKS permissions for infrastructure management  
resource "aws_iam_role_policy_attachment" "terraform_admin_eks" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EC2 permissions for infrastructure management
resource "aws_iam_role_policy_attachment" "terraform_admin_ec2" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# CloudWatch permissions for infrastructure management
resource "aws_iam_role_policy_attachment" "terraform_admin_cloudwatch" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# ===== APPLICATION DEPLOY ROLE PERMISSIONS =====
# ECR permissions for application deployment
resource "aws_iam_role_policy_attachment" "deploy_ecr_poweruser" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# EKS deployment permissions (limited)
resource "aws_iam_role_policy" "deploy_eks_limited" {
  name = "${var.vti_id}-${var.environment}-deploy-eks-limited"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch readonly for monitoring
resource "aws_iam_role_policy_attachment" "deploy_cloudwatch_readonly" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Add limited IAM permissions for role management
# Temporarily commented out to avoid chicken-and-egg problem
# resource "aws_iam_role_policy" "iam_limited_access" {
#   name = "${var.vti_id}-${var.environment}-iam-limited-access"
#   role = aws_iam_role.github_actions.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "iam:CreateRole",
#           "iam:DeleteRole",
#           "iam:AttachRolePolicy",
#           "iam:DetachRolePolicy",
#           "iam:CreatePolicy",
#           "iam:DeletePolicy",
#           "iam:GetPolicy",
#           "iam:GetPolicyVersion",
#           "iam:PassRole",
#           "iam:TagRole",
#           "iam:UntagRole",
#           "iam:TagPolicy",
#           "iam:UntagPolicy",
#           "iam:UpdateAssumeRolePolicy",
#           "iam:PutRolePolicy"
#         ]
#         Resource = [
#           "arn:aws:iam::*:role/*eks*",
#           "arn:aws:iam::*:role/*EKS*",
#           "arn:aws:iam::*:role/*nodegroup*",
#           "arn:aws:iam::*:role/*external-secrets*",
#           "arn:aws:iam::*:policy/*external-secrets*",
#           "arn:aws:iam::*:role/*github-actions*"
#         ]
#       }
#     ]
#   })
# }

# ===== TERRAFORM ADMIN ROLE ADDITIONAL PERMISSIONS =====
# Custom policy for advanced Terraform operations
resource "aws_iam_role_policy" "terraform_admin_operations" {
  name = "${var.vti_id}-${var.environment}-terraform-admin-operations"
  role = aws_iam_role.terraform_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListOpenIDConnectProviders",
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "eks:*",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "ecr:*",
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:DeleteResourcePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 policy cho Terraform state access (admin role)
resource "aws_iam_role_policy" "terraform_admin_state_access" {
  name = "${var.vti_id}-${var.environment}-terraform-admin-state-access"
  role = aws_iam_role.terraform_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::de000079-terraform-state",
          "arn:aws:s3:::de000079-terraform-state/*"
        ]
      }
    ]
  })
}

# ===== EXTERNAL SECRETS IRSA ROLE =====
resource "aws_iam_role" "external_secrets_irsa" {
  name = "${var.vti_id}-${var.environment}-external-secrets-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:external-secrets-sa"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.vti_id}-${var.environment}-external-secrets-irsa"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "external-secrets-irsa"
  }
}

resource "aws_iam_policy" "external_secrets_access" {
  name        = "${var.vti_id}-${var.environment}-external-secrets-access"
  description = "Allow External Secrets Operator to access AWS Secrets Manager"

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
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_attach" {
  role       = aws_iam_role.external_secrets_irsa.name
  policy_arn = aws_iam_policy.external_secrets_access.arn
}
