output "eks_cluster_log_group_name" {
  description = "The CloudWatch Logs group name for EKS cluster logs"
  value       = local.cluster_log_group.name
}

output "eks_logs_log_group_name" {
  description = "The CloudWatch Logs group name for EKS pod/application logs"
  value       = local.logs_log_group.name
}
