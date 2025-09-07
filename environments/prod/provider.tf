terraform {
  backend "s3" {
    bucket = "de000079-terraform-state"
    key    = "environments/prod/terraform.tfstate"
    region = "ap-southeast-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.9.0"
    }
  }

  required_version = ">= 1.12.0"
}