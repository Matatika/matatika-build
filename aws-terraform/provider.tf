provider "aws" {
  region = var.aws_region

  #   assume_role {
  #     role_arn     = var.assume_role_arn
  #     session_name = "terraform-${var.environment}"
  #   }

  default_tags {
    tags = {
      map-migrated = "TBD"
      environment  = var.environment
    }
  }
}

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
