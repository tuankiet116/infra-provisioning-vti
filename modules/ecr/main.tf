module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${lower(var.vti_id)}-ecr-repo-${var.environment}"

  repository_read_write_access_arns = var.read_write_arns
  repository_image_scan_on_push     = true
  repository_force_delete           = var.force_delete_ecr

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
