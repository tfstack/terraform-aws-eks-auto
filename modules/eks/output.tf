output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_version" {
  description = "The Kubernetes version used for the EKS cluster"
  value       = aws_eks_cluster.this.version
}
