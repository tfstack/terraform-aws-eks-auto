output "eks_auto_nodes_role_arn" {
  description = "ARN of the IAM role used by EKS worker nodes (autoscaling group)"
  value       = aws_iam_role.eks_auto_nodes.arn
}

output "eks_fargate_role_arn" {
  description = "ARN of the IAM Role used for EKS Fargate"
  value       = aws_iam_role.eks_fargate.arn
}
