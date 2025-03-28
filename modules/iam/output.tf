
output "eks_auto_cluster_role_arn" {
  description = "IAM Role ARN for the EKS Auto Mode control plane"
  value       = aws_iam_role.eks_auto_cluster.arn
}

output "eks_auto_node_role_arn" {
  description = "IAM Role ARN for EKS Auto Mode EC2 nodes"
  value       = aws_iam_role.eks_auto_node.arn
}

output "metrics_server_irsa_role_arn" {
  value       = try(aws_iam_role.metrics_server[0].arn, null)
  description = "IAM Role ARN for metrics-server service account"
}
