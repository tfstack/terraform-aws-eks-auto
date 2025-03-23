output "cluster_version" {
  description = "The Kubernetes version used for the EKS cluster"
  value       = local.resolved_eks_version != null ? local.resolved_eks_version : "latest (managed by EKS)"
}
