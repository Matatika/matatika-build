resource "time_sleep" "wait_3_minutes" {
  depends_on = [module.eks]

  create_duration = "3m"
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = var.environment
  addon_name        = "coredns"
  addon_version     = var.eks_addons_versions.coredns
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve = true
  depends_on = [aws_eks_addon.vpc_cni]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = var.environment
  addon_name        = "kube-proxy"
  addon_version     = var.eks_addons_versions.kube_proxy
  depends_on = [time_sleep.wait_3_minutes]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = var.environment
  addon_name        = "vpc-cni"
  addon_version     = var.eks_addons_versions.vpc_cni
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve = true
  depends_on = [time_sleep.wait_3_minutes]
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name      = var.environment
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = var.eks_addons_versions.aws_ebs_csi_driver
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve = true
  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
  depends_on = [time_sleep.wait_3_minutes]
}
