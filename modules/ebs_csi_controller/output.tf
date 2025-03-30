#########################################
# Outputs: EBS CSI Controller
#########################################

output "ebs_csi_controller_role_arn" {
  description = "IAM Role ARN used by the EBS CSI Controller for IRSA"
  value       = try(aws_iam_role.ebs_csi_controller_irsa[0].arn, null)
}

output "ebs_csi_controller_service_account_name" {
  description = "Name of the Kubernetes ServiceAccount used by the EBS CSI Controller"
  value       = try(kubernetes_service_account.ebs_csi_controller[0].metadata[0].name, null)
}

output "ebs_csi_controller_service_account_namespace" {
  description = "Namespace where the EBS CSI Controller ServiceAccount is deployed"
  value       = try(kubernetes_service_account.ebs_csi_controller[0].metadata[0].namespace, null)
}

output "ebs_csi_driver_release_name" {
  description = "Name of the Helm release for the AWS EBS CSI Driver"
  value       = try(helm_release.ebs_csi_driver[0].name, null)
}
