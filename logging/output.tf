# output "cloudwatch_namespace_name" {
#   description = "The name of the namespace used for CloudWatch Fluent Bit configuration"
#   value       = kubernetes_namespace.cloudwatch.metadata[0].name
# }

# output "fluentbit_configmap_name" {
#   description = "The name of the aws-logging ConfigMap"
#   value       = kubernetes_config_map.logging.metadata[0].name
# }

# output "log_group_name" {
#   description = "The CloudWatch Logs group name configured for EKS Fargate logs"
#   value       = "/aws/eks/${var.cluster_name}/logs"
# }
