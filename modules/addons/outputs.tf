#########################################
# EKS Addons Module Outputs
#########################################

output "addon_names" {
  description = "List of installed addon names"
  value       = [for addon in aws_eks_addon.this : addon.addon_name]
}

output "addon_versions" {
  description = "Map of addon names to their versions"
  value = {
    for addon in aws_eks_addon.this : addon.addon_name => addon.addon_version
  }
}

output "addon_arns" {
  description = "Map of addon names to their ARNs"
  value = {
    for addon in aws_eks_addon.this : addon.addon_name => addon.arn
  }
}

#########################################
# AWS Load Balancer Controller Outputs
#########################################

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "aws_load_balancer_controller_service_account_name" {
  description = "Name of the AWS Load Balancer Controller service account"
  value       = var.enable_aws_load_balancer_controller ? kubernetes_service_account.aws_load_balancer_controller[0].metadata[0].name : null
}

output "aws_load_balancer_controller_service_account_namespace" {
  description = "Namespace of the AWS Load Balancer Controller service account"
  value       = var.enable_aws_load_balancer_controller ? kubernetes_service_account.aws_load_balancer_controller[0].metadata[0].namespace : null
}
