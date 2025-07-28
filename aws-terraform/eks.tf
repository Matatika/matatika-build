module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31"

  cluster_name    = var.environment
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true # needs route table update for private subnet
  # with VPN CIDRs if private endpoint only

  enable_cluster_creator_admin_permissions = false
  create_cloudwatch_log_group              = true

  enable_irsa = true

  cluster_compute_config = { # Uncomment for EKS Auto Mode (not appropriate for now as nodes require labels)
    enabled    = true
    node_pools = ["general-purpose"]
  }

  cluster_addons = {
    coredns = {
      addon_version = var.eks_addons_versions.coredns
    }
    kube-proxy = {
      addon_version = var.eks_addons_versions.kube_proxy
    }
    vpc-cni = {
      addon_version = var.eks_addons_versions.vpc_cni
    }
		aws-ebs-csi-driver = {
			most_recent              = true
			resolve_conflicts        = "OVERWRITE"
			service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
		}
  }

  cluster_encryption_config = {
    resources = ["secrets"]
    provider = {
      key_arn = aws_kms_key.eks.arn
    }
  }

  cluster_security_group_name = "${var.environment}-eks-cluster"
  cluster_security_group_additional_rules = {
    ingress_vpc = {
      description = "Access EKS from VPC CIDR and VPN."
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  access_entries = {
    kubernetes-admin = {
      principal_arn = tolist(data.aws_iam_roles.sso_admin.arns)[0]
      policy_associations = {
        kubernetes-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # kubernetes-read-only = {
    #   principal_arn = 
    #   policy_associations = {
    #     kubernetes-admin = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    #       access_scope = {
    #         type = "cluster"
    #       }
    #     }
    #   }
    # }
  }
}

# KMS key
resource "aws_kms_key" "eks" {

  description             = "${var.environment}-eks-kms"
  is_enabled              = true
  enable_key_rotation     = true
  deletion_window_in_days = var.key_deletion_days

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "default"
    Statement = [
      {
        Sid    = "default"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          ]
        }
        Action = [
          "kms:*",
        ]
        Resource = "*"
      },
    ]
  })

}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.environment}-eks-kms"
  target_key_id = aws_kms_key.eks.key_id
}
