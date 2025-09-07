# Data source để lấy OIDC provider đã tạo từ shared-resources
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name = "${var.vti_id}-${var.environment}-github-actions"

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
    Name        = "${var.vti_id}-${var.environment}-github-actions"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "github-actions-ecr-access"
  }
}

# Gán quyền cho ECR + EKS
resource "aws_iam_role_policy_attachment" "ecr_poweruser" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "eks_fullaccess" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Additional AWS permissions for Terraform operations
resource "aws_iam_role_policy_attachment" "ec2_readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "vpc_fullaccess" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Add limited IAM permissions for role management
resource "aws_iam_role_policy" "iam_limited_access" {
  name = "${var.vti_id}-${var.environment}-iam-limited-access"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::*:role/*eks*",
          "arn:aws:iam::*:role/*EKS*",
          "arn:aws:iam::*:role/*nodegroup*",
          "arn:aws:iam::*:role/*external-secrets*",
          "arn:aws:iam::*:policy/*external-secrets*",
          "arn:aws:iam::*:role/*github-actions*"
        ]
      }
    ]
  })
}

# Custom policy for IAM and additional EKS permissions
resource "aws_iam_role_policy" "terraform_operations" {
  name = "${var.vti_id}-${var.environment}-terraform-operations"
  role = aws_iam_role.github_actions.id

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

# S3 policy cho Terraform state access
resource "aws_iam_role_policy" "terraform_state_access" {
  name = "${var.vti_id}-${var.environment}-terraform-state-access"
  role = aws_iam_role.github_actions.id

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

# === IRSA for External Secrets Operator ===
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
