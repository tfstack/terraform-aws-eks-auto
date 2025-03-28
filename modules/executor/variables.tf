variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  type        = string
}

variable "enable_executor_cluster_admin" {
  description = "Whether to grant AmazonEKSClusterAdminPolicy to the IAM role running Terraform"
  type        = bool
  default     = false
}

variable "enable_k8s_api_wait" {
  description = "If true, wait for Kubernetes API to become ready before continuing"
  type        = bool
  default     = true
}

variable "k8s_api_wait_attempts" {
  description = "Number of retry attempts when waiting for Kubernetes API"
  type        = number
  default     = 30
}

variable "k8s_api_wait_interval" {
  description = "Seconds to wait between each retry attempt"
  type        = number
  default     = 5
}
