variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_log_retention_days" {
  description = "The number of days to retain logs for the EKS in CloudWatch"
  type        = number
  default     = 30
}
