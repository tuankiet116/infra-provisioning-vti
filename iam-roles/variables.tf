variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "tuankiet116"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "infra-provisioning-vti"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-vti-infra"
}
