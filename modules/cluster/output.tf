#########################################
# EKS Cluster Outputs
#########################################

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_version" {
  description = "The Kubernetes version used for the EKS cluster"
  value       = aws_eks_cluster.this.version
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_ca_cert" {
  description = "The base64-decoded certificate authority data for the EKS cluster"
  value       = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
}

output "eks_cluster_auth_token" {
  description = "Authentication token for the EKS cluster (used by kubectl and SDKs)"
  value       = data.aws_eks_cluster_auth.this.token
  sensitive   = true
}

#########################################
# OIDC Identity Provider (IRSA)
#########################################

output "oidc_provider_arn" {
  value = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "oidc_provider_url" {
  value = try(aws_iam_openid_connect_provider.this[0].url, null)
}

#########################################
# EKS IAM Role ARNs (Auto Mode)
#########################################

output "eks_auto_cluster_role_arn" {
  description = "IAM Role ARN for the EKS Auto Mode control plane"
  value       = aws_iam_role.eks_auto_cluster.arn
}

output "eks_auto_node_role_arn" {
  description = "IAM Role ARN for EKS Auto Mode EC2 nodes"
  value       = aws_iam_role.eks_auto_node.arn
}
