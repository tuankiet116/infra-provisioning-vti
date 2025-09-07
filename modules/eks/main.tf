# Data sources
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${var.vti_id}-eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_group" {
  count = var.create_node_groups ? 1 : 0
  name  = "${var.vti_id}-eks-node-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.create_node_groups ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.create_node_groups ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.create_node_groups ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group[0].name
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.vti_id}-eks-cluster-${var.environment}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.vti_id}-eks-cluster-sg-${var.environment}"
    Environment = var.environment
    Terraform   = "true"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.vti_id}-eks-${var.environment}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.33"

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Enable logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  count           = var.create_node_groups ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.vti_id}-node-group-${var.environment}"
  node_role_arn   = aws_iam_role.eks_node_group[0].arn
  subnet_ids      = var.subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = {
    Name        = "${var.vti_id}-node-${var.environment}"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Extract OIDC issuer URL from EKS cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Create OIDC provider for EKS cluster
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.vti_id}-eks-oidc-provider-${var.environment}"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Data source to get current AWS region
data "aws_region" "current" {}

# Create aws-auth ConfigMap to allow GitHub Actions roles access to EKS
resource "local_file" "aws_auth" {
  count = var.github_actions_deploy_role_arn != "" ? 1 : 0
  
  content = templatefile("${path.module}/aws-auth-template.yaml", {
    node_instance_role_arn = var.create_node_groups ? aws_iam_role.eks_node_group[0].arn : ""
    terraform_admin_role_arn = var.github_actions_terraform_admin_role_arn
    deploy_role_arn = var.github_actions_deploy_role_arn
  })
  
  filename = "${path.module}/aws-auth-${var.environment}.yaml"
}

# Apply aws-auth ConfigMap and RBAC to EKS cluster
resource "null_resource" "aws_auth" {
  count = var.github_actions_deploy_role_arn != "" ? 1 : 0
  
  triggers = {
    cluster_name = aws_eks_cluster.main.name
    config_hash  = local_file.aws_auth[0].content_md5
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Assume terraform admin role to get credentials for kubectl
      CREDS=$(aws sts assume-role --role-arn ${var.github_actions_terraform_admin_role_arn} --role-session-name terraform-kubectl --output json)
      export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
      export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
      export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
      
      # Update kubeconfig and apply aws-auth
      aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}
      kubectl apply -f ${local_file.aws_auth[0].filename} --validate=false
      kubectl apply -f ${path.module}/github-actions-rbac.yaml --validate=false
    EOT
  }

  depends_on = [aws_eks_cluster.main, local_file.aws_auth]
}
