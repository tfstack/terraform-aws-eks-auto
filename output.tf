output "cluster_version" {
  description = "The Kubernetes version used by the EKS cluster, if exported by the module."
  value       = try(module.cluster.cluster_version, "unknown")
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = module.cluster.eks_cluster_endpoint
}

output "eks_cluster_ca_cert" {
  description = "The base64-decoded certificate authority data for the EKS cluster"
  value       = module.cluster.eks_cluster_ca_cert
}

output "eks_cluster_auth_token" {
  description = "Authentication token for the EKS cluster (used by kubectl and SDKs)"
  value       = module.cluster.eks_cluster_auth_token
  sensitive   = true
}
