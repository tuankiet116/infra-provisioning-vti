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
    # Cấu hình này sẽ được set trong terraform init
    key = "shared-resources/terraform.tfstate"
  }
}
