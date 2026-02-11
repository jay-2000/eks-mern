resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.mern_eks.name
  node_group_name = "mern-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  instance_types = ["t3.medium"]
}
