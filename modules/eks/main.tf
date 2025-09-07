# Required providers
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name, "--region", data.aws_region.current.name]
  }
}

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

# Kubernetes provider configuration
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

# Create aws-auth ConfigMap using kubernetes provider instead of kubectl
resource "kubernetes_config_map_v1" "aws_auth" {
  count = var.github_actions_deploy_role_arn != "" ? 1 : 0
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      var.create_node_groups ? [{
        rolearn  = aws_iam_role.eks_node_group[0].arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }] : [],
      var.github_actions_terraform_admin_role_arn != "" ? [{
        rolearn  = var.github_actions_terraform_admin_role_arn
        username = "github-actions-terraform-admin"
        groups   = ["system:masters"]
      }] : [],
      var.github_actions_deploy_role_arn != "" ? [{
        rolearn  = var.github_actions_deploy_role_arn
        username = "github-actions-deploy"
        groups   = ["system:authenticated"]
      }] : []
    ))
  }

  depends_on = [aws_eks_cluster.main]
}

# Create ClusterRole for GitHub Actions deploy
resource "kubernetes_cluster_role_v1" "github_actions_deploy" {
  count = var.github_actions_deploy_role_arn != "" ? 1 : 0
  
  metadata {
    name = "github-actions-deploy"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/status"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  depends_on = [kubernetes_config_map_v1.aws_auth]
}

# Create ClusterRoleBinding for GitHub Actions deploy
resource "kubernetes_cluster_role_binding_v1" "github_actions_deploy" {
  count = var.github_actions_deploy_role_arn != "" ? 1 : 0
  
  metadata {
    name = "github-actions-deploy"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.github_actions_deploy[0].metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "github-actions-deploy"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [kubernetes_cluster_role_v1.github_actions_deploy]
}
