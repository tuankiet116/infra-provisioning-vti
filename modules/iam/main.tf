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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
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