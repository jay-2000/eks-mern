###########################################
# EKS CLUSTER
###########################################
resource "aws_eks_cluster" "mern_eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.30"

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attach,
    aws_iam_role_policy_attachment.eks_vpc_controller_attach
  ]

  tags = {
    Name = "mern-eks"
  }
}

###########################################
# OUTPUT: OIDC ISSUER URL (REQUIRED FOR IRSA)
###########################################
output "eks_oidc_issuer" {
  description = "OIDC issuer URL for IRSA"
  value       = aws_eks_cluster.mern_eks.identity[0].oidc[0].issuer
}
