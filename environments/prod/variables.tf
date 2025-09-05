variable "vti_id" {
  description = "The ID of the VTI to attach the VPN connection to."
  type        = string
}

variable "environment" {
  description = "The environment for the resources (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "create_node_groups" {
  type        = bool
  description = "Whether to create EKS managed node groups"
  default     = true
}

variable "github_org" {
  type        = string
  description = "Github org or username"
}

variable "github_repo" {
  type        = string
  description = "Github repo name"
}