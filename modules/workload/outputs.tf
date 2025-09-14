#########################################
# Workload Module Outputs
#########################################

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.this.metadata[0].name
}

output "deployment_namespace" {
  description = "Namespace of the Kubernetes deployment"
  value       = kubernetes_deployment.this.metadata[0].namespace
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = var.create_service ? kubernetes_service.this[0].metadata[0].name : null
}

output "service_namespace" {
  description = "Namespace of the Kubernetes service"
  value       = var.create_service ? kubernetes_service.this[0].metadata[0].namespace : null
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.this.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = kubernetes_service_account.this.metadata[0].namespace
}

output "irsa_role_arn" {
  description = "ARN of the IAM role for IRSA"
  value       = var.irsa.enabled ? aws_iam_role.irsa[0].arn : null
}

output "namespace_name" {
  description = "Name of the created namespace"
  value       = var.create_namespace ? kubernetes_namespace.this[0].metadata[0].name : var.namespace
}

output "ingress_name" {
  description = "Name of the Kubernetes ingress"
  value       = var.create_ingress ? kubernetes_ingress_v1.this[0].metadata[0].name : null
}

output "ingress_namespace" {
  description = "Namespace of the Kubernetes ingress"
  value       = var.create_ingress ? kubernetes_ingress_v1.this[0].metadata[0].namespace : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value = var.create_ingress ? try(
    kubernetes_ingress_v1.this[0].status[0].load_balancer[0].ingress[0].hostname,
    null
  ) : null
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value = var.create_ingress ? try(
    "${var.ingress_protocol}://${kubernetes_ingress_v1.this[0].status[0].load_balancer[0].ingress[0].hostname}",
    null
  ) : null
}
