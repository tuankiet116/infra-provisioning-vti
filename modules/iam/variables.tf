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
