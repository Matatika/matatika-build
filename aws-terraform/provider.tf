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

provider "kubernetes" {
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.33.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16.1"
    }
  }
}
