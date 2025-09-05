variable "vti_id" {
  description = "The ID of the VTI to attach the VPN connection to."
  type        = string
}

variable "environment" {
  description = "The environment for the resources (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "read_write_arns" {
  type        = list(string)
  description = "Danh sách ARN được push/pull image"
}
