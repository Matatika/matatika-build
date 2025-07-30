module "ebs_csi_irsa_role" {
	source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

	role_name             = "ebs-csi"
	attach_ebs_csi_policy = true

	oidc_providers = {
		ex = {
			provider_arn               = module.eks.oidc_provider_arn
			namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
		}
	}
}

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  role_policy_arns = {
    "additional_lb_policy" = aws_iam_policy.additional_lb_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.2"

  values = [
    <<-VALUES
       clusterName: ${module.eks.cluster_name}
       replicaCount: 1
       serviceAccount:
         name: aws-load-balancer-controller
         annotations:
           eks.amazonaws.com/role-arn: ${module.aws_load_balancer_controller_irsa_role.iam_role_arn}
       vpcId: ${module.vpc.vpc_id}
       region: ${data.aws_region.current.region}
       image:
        repository: public.ecr.aws/eks/aws-load-balancer-controller
        tag: v2.13.2
       clusterRole:
         extraRules:
           - apiGroups:
               - coordination.k8s.io
             resources:
               - leases
             verbs:
               - get
               - watch
               - list
               - create
               - update
               - patch
       VALUES
  ]
}

resource "kubernetes_cluster_role" "aws_lb_controller_lease_patch" {
  metadata {
    name = "aws-lb-controller-lease-access"
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "watch", "list", "create", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "aws_lb_controller_lease_patch_binding" {
  metadata {
    name = "aws-lb-controller-lease-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.aws_lb_controller_lease_patch.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "aws_iam_policy" "additional_lb_policy" {
  name   = "additional_lb_policy"
  policy = data.aws_iam_policy_document.additional_lb_policy.json
}

data "aws_iam_policy_document" "additional_lb_policy" {
  statement {
    sid = ""
    actions = [
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:AddTags"
    ]
    effect = "Allow"
    resources = concat(
      [
        "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
      ]
    )
  }

  statement {
    actions = [
      "ec2:DescribeRouteTables",
      "ec2:GetSecurityGroupsForVpc",
      "elasticloadbalancing:DescribeListenerAttributes"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

module "external_dns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "external-dns"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = "operations"
  version    = "1.12.0"

  set_sensitive = [
    {
      name  = "env[0].name"
      value = "CF_API_TOKEN"
    },
    {
    name  = "env[0].value"
    value = data.aws_secretsmanager_secret_version.cloudflare.secret_string
    }
  ]

  values = [
    <<-VALUES
       provider: cloudflare
       policy: sync
       domainFilters:
        - ${var.domain_name}
       txtOwnerId: externaldns-${var.environment}
       serviceAccount:
        create: true
        name: external-dns
       VALUES
  ]
}

