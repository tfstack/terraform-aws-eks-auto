#########################################
# Output: Fluent Bit IRSA Role ARN
#########################################

output "fluentbit_irsa_role_arn" {
  value       = try(aws_iam_role.fluentbit_irsa[0].arn, null)
  description = "IAM Role ARN for the Fluent Bit service account used for IRSA integration with CloudWatch Logs"
}
