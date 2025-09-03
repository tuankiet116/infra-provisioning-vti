module "dev" {
  source = "../../modules/networking"

  vti_id      = var.vti_id
  environment = var.environment
}
