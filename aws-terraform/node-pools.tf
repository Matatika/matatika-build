# resource "aws_eks_node_group" "esystempool" {
#   cluster_name    = module.eks.cluster_name
#   node_group_name = "esystempool"
#   node_role_arn   = aws_iam_role.eks_node_group_role.arn
#   subnet_ids      = module.vpc.private_subnets
#   instance_types  = ["t3.medium"]

#   scaling_config {
#     desired_size = 1
#     min_size     = 1
#     max_size     = 1
#   }
# }

resource "aws_eks_node_group" "nodepool1" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "nodepool1"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  labels = {
    "agentpool" = "nodepool1"
    "env"       = "${var.environment}"
  }
}

resource "aws_eks_node_group" "appspool" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "appspool"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 3
  }

  labels = {
    "agentpool" = "appspool"
    "env"       = "${var.environment}"
  }
}

resource "aws_eks_node_group" "apps" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.environment}apps"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  labels = {
    "agentpool" = "${var.environment}apps"
    "env"       = "${var.environment}"
  }
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
