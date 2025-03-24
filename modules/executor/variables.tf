variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_executor_cluster_admin" {
  description = "Whether to grant AmazonEKSClusterAdminPolicy to the IAM role running Terraform"
  type        = bool
  default     = false
}
