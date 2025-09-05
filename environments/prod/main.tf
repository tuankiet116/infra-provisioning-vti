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
  source      = "../../modules/iam"
  vti_id      = var.vti_id
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  github_org  = var.github_org
  github_repo = var.github_repo
}

module "ecr" {
  source      = "../../modules/ecr"
  vti_id      = var.vti_id
  environment = var.environment
  read_write_arns = [
    module.iam.github_actions_role_arn
  ]
}
