data "aws_caller_identity" "current" {}

module "networking" {
  source      = "../../modules/networking"
  vti_id      = var.vti_id
  environment = var.environment
}

module "eks" {
  source = "../../modules/eks"

  vti_id             = var.vti_id
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnets
  account_id         = data.aws_caller_identity.current.account_id
  create_node_groups = var.create_node_groups

  depends_on = [module.networking]
}

module "iam" {
  source                      = "../../modules/iam"
  vti_id                      = var.vti_id
  environment                 = var.environment
  account_id                  = data.aws_caller_identity.current.account_id
  github_org                  = var.github_org
  github_repo                 = var.github_repo
  additional_trusted_repos    = var.additional_trusted_repos
  additional_trusted_branches = var.additional_trusted_branches
  eks_oidc_provider_arn       = module.eks.oidc_provider_arn
  eks_oidc_provider_url       = module.eks.oidc_provider_url
  external_secrets_namespace  = "ecommerce-vti-prod"
}

module "ecr" {
  source      = "../../modules/ecr"
  vti_id      = var.vti_id
  environment = var.environment
  read_write_arns = [
    module.iam.github_actions_deploy_role_arn,
    module.iam.terraform_admin_role_arn
  ]
}

module "external_secrets" {
  source = "../../modules/external-secrets"

  vti_id                = var.vti_id
  environment           = var.environment
  aws_region            = "ap-southeast-2"
  eks_cluster_name      = module.eks.cluster_name
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider_url = module.eks.oidc_provider_url

  depends_on = [module.eks]
}
