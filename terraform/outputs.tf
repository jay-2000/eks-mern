output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}

output "eks_cluster_name" {
  value = aws_eks_cluster.mern_eks.name
}
