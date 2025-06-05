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
  version    = "1.4.4"

  values = [
    <<-VALUES
       clusterName: ${module.eks.cluster_name}
       replicaCount: 1
       serviceAccount:
         name: aws-load-balancer-controller
         annotations:
           eks.amazonaws.com/role-arn: ${module.aws_load_balancer_controller_irsa_role.iam_role_arn}
       vpcId: ${module.vpc.vpc_id}
       region: ${data.aws_region.current.name}
       image:
        repository: public.ecr.aws/eks/aws-load-balancer-controller
        tag: v2.13.2
       VALUES
  ]
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

  values = [
    <<-VALUES
       provider: cloudflare
       cloudflare:
         apiToken: ${data.aws_secretsmanager_secret_version.cloudflare.secret_string}
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

