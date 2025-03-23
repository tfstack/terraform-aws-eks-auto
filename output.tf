##############################
# Outputs: EKS Cluster
##############################

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

##############################
# Outputs: IAM Role
##############################

output "eks_fargate_role_arn" {
  description = "The ARN of the IAM role used by EKS Fargate"
  value       = aws_iam_role.eks_fargate.arn
}

##############################
# Outputs: Deployed Applications
##############################

output "apps_deployed" {
  description = "List of application names that were deployed"
  value       = length(module.apps) > 0 ? module.apps[0].deployed_apps : []
}

output "apps_namespace_map" {
  description = "Map of application name to deployed namespace"
  value       = length(module.apps) > 0 ? module.apps[0].app_namespaces : {}
}

##############################
# Outputs: Logging Configuration
##############################

output "logging_namespace_name" {
  description = "The name of the namespace used for CloudWatch Fluent Bit configuration"
  value       = try(module.logging.logging_namespace_name, null)
}

output "logging_configmap_name" {
  description = "The name of the aws-logging ConfigMap"
  value       = try(module.logging.logging_configmap_name, null)
}

output "eks_fargate_log_group_name" {
  description = "The CloudWatch Logs group name configured for EKS Fargate logs"
  value       = try(module.logging.eks_fargate_log_group_name, null)
}
