module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.vti_id}-eks-${var.environment}"
  kubernetes_version = "1.33"

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  eks_managed_node_groups = {
    default = {
      create         = true
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      partition      = "aws"          # thêm tránh count logic fail
      account_id     = var.account_id # tránh unknown
      tags = {
        Name = "${var.vti_id}-node-${var.environment}"
      }
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
