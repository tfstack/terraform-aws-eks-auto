output "logging_namespace_name" {
  description = "The Kubernetes namespace used for Fluent Bit logging configuration"
  value       = length(kubernetes_namespace.aws_observability) > 0 ? kubernetes_namespace.aws_observability.metadata[0].name : null
}

output "logging_configmap_name" {
  description = "The name of the ConfigMap used for Fluent Bit log routing"
  value       = length(kubernetes_config_map.aws_logging) > 0 ? kubernetes_config_map.aws_logging.metadata[0].name : null
}

output "eks_cluster_log_group_name" {
  description = "The CloudWatch Logs group name for EKS cluster logs"
  value       = local.cluster_log_group.name
}

output "eks_logs_log_group_name" {
  description = "The CloudWatch Logs group name for EKS pod/application logs"
  value       = local.logs_log_group.name
}
