module "networking" {
  source = "../../modules/networking"

  vti_id      = var.vti_id
  environment = var.environment
}

module "eks" {
  source = "../../modules/eks"

  vti_id      = var.vti_id
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnets

  depends_on = [module.networking]
}
