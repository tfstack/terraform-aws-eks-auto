##############################
# Variables: EKS Cluster Configuration
##############################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_cloudwatch_logging" {
  description = "Whether to enable CloudWatch logging for EKS workloads (e.g., Fluent Bit, Fargate logs)"
  type        = bool
  default     = false
}
