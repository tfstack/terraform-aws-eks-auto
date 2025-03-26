variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_observability_namespace" {
  description = "Name of the namespace used for Fluent Bit/observability"
  type        = string
  default     = "aws-observability"
}

variable "eks_log_retention_days" {
  description = "The number of days to retain logs for the EKS in CloudWatch"
  type        = number
  default     = 30
}

variable "executor_dependency" {
  description = "Dummy input to establish a dependency on the executor module"
  type        = string
  default     = null
}
