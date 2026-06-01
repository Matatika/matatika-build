locals {
  apps_node_group_subnet_ids = (
    var.apps_node_group_subnet_ids != null
    ? var.apps_node_group_subnet_ids
    : var.apps_node_group_azs != null
    ? [for s in data.aws_subnet.private : s.id if contains(var.apps_node_group_azs, s.availability_zone)]
    : module.vpc.private_subnets
  )
}

# Node pool for tasks
resource "aws_eks_node_group" "nodepool1" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "nodepool1"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    # Raised from 3 -> 6 (2026-05-19). Concurrent shelltask load + the heavier
    # per-pod memory footprint after the MEL-386 heap bump (Xmx 128M -> 256M)
    # was filling 3 t3.medium nodes and leaving pods stuck Pending. EKS Auto Mode
    # cannot absorb overflow because its provisioner does not recognise the
    # `agentpool` label used here.
    max_size     = 6
  }

  tags = {
    "k8s.io/cluster-autoscaler/enabled"                    = "true"
    "k8s.io/cluster-autoscaler/${module.eks.cluster_name}" = "owned"
    "env"                                                  = var.environment
  }

  labels = {
    "agentpool" = "nodepool1"
    "env"       = "${var.environment}"
  }

  depends_on = [aws_eks_addon.vpc_cni]
}

# Node pool for the catalog, elastic search, logstash and main components.
resource "aws_eks_node_group" "apps" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "apps"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = local.apps_node_group_subnet_ids
  instance_types  = ["m5.xlarge"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 3
  }

  labels = {
    "agentpool" = "apps"
    "env"       = "${var.environment}"
  }

  tags = {
    "k8s.io/cluster-autoscaler/enabled"                    = "true"
    "k8s.io/cluster-autoscaler/${module.eks.cluster_name}" = "owned"
    "env"                                                  = var.environment
  }

  depends_on = [aws_eks_addon.vpc_cni]
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = each.key
}
