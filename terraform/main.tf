locals {
  ecr_image = "${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}:latest"
}

terraform {
  required_providers {
    aws = {
      source        = "hashicorp/aws"
      version       = "~> 5.97.0"
    }
  }
  backend s3 {
    bucket          = "fargate-ecr-otel-poc-tfstate"
    key             = "terraform.tfstate"
    region          = "us-east-1"
    encrypt         = false
  }
}

provider aws {
  region            = var.aws_region
}