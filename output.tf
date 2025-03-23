output "cluster_version" {
  description = "The Kubernetes version used by the EKS cluster, if exported by the module."
  value       = try(module.eks.cluster_version, "unknown")
}
