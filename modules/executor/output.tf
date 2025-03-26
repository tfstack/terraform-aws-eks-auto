output "executor_access_entry_principal_arn" {
  description = "The principal ARN used in EKS access entry for Terraform executor"
  value       = try(aws_eks_access_entry.terraform_executor[0].principal_arn, null)
}
