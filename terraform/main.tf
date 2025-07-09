locals {
  ecr_image = "${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}:${var.ecr_repo_version}"
}

terraform {
  required_providers {
    aws = {
      source        = "hashicorp/aws"
      version       = "~> 5.97.0"
    }
  }
  # set this during initialization using `terraform init -backend-config="backend/nonprod.config"`
  backend s3 {
    bucket          = ""
    key             = ""
    region          = ""
  }
}

provider aws {
  region            = var.aws_region
}