resource "aws_eks_node_group" "spot_nodes" {
  cluster_name    = aws_eks_cluster.mern_eks.name
  node_group_name = "spot-ng"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  capacity_type = "SPOT"

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.mern_eks
  ]
}
