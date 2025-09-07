variable "vti_id" {
  description = "The ID of the VTI to attach the VPN connection to."
  type        = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "account_id" {
  type = string
}

variable "github_org" {
  type        = string
  description = "Tên GitHub org hoặc username"
}

variable "github_repo" {
  type        = string
  description = "Tên GitHub repo"
}

variable "additional_trusted_repos" {
  type        = list(string)
  description = "Danh sách các repos khác được trust bởi IAM role"
  default     = []
}

variable "additional_trusted_branches" {
  type        = list(string)
  description = "Danh sách các branches khác được trust bởi IAM role (ngoài main/master)"
  default     = []
}

# Thêm biến cho OIDC provider từ EKS
variable "eks_oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "eks_oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider"
}

# Namespace của ServiceAccount External Secrets Operator
variable "external_secrets_namespace" {
  type        = string
  description = "Namespace của ServiceAccount External Secrets Operator"
}
