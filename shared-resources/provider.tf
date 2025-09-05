terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9.0"
    }
  }

  required_version = ">= 1.5.0"
}

# Remote state để lưu trạng thái shared resources
terraform {
  backend "s3" {
    bucket = "de000079-terraform-state"
    key    = "shared-resources/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

# AWS Provider configuration
provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = {
      Environment = "shared"
      ManagedBy   = "terraform"
      Project     = "infra-provisioning-vti"
    }
  }
}
