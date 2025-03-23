output "logging_namespace_name" {
  description = "The Kubernetes namespace used for Fluent Bit logging configuration"
  value       = length(kubernetes_namespace.aws_observability) > 0 ? kubernetes_namespace.aws_observability.metadata[0].name : null
}

output "logging_configmap_name" {
  description = "The name of the ConfigMap used for Fluent Bit log routing"
  value       = length(kubernetes_config_map.aws_logging) > 0 ? kubernetes_config_map.aws_logging.metadata[0].name : null
}

output "eks_fargate_log_group_name" {
  description = "The name of the CloudWatch Logs group used for EKS Fargate logging"
  value       = "/aws/eks/${var.cluster_name}/logs"
}
