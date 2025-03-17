resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "free-tier-nodes"
  node_role_arn   = aws_iam_role.eks_role.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = ["t3.micro"]  # Free-tier instance

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }
}
