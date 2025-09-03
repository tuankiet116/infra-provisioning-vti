variable "vti_id" {
    description = "The ID of the VTI to attach the VPN connection to."
    type        = string
}

variable "environment" {
    description = "The environment for the resources (e.g., dev, prod)."
    type        = string
    default     = "dev"
}

variable "vpc_id" {
    description = "The ID of the VPC where the EKS cluster will be deployed."
    type        = string
}

variable "subnet_ids" {
    description = "A list of subnet IDs where the EKS cluster nodes will be deployed."
    type        = list(string)
}

variable "account_id" {
  type        = string
  description = "AWS account ID for IRSA"
  default     = ""
}