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

variable "enable_executor_cluster_admin" {
  description = "Whether to grant AmazonEKSClusterAdminPolicy to the IAM role running Terraform"
  type        = bool
  default     = false
}

variable "enable_metrics_server_irsa" {
  description = "Enable creation of IRSA IAM role for metrics-server. If true, requires OIDC provider ARN and URL."
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS cluster (used for IRSA). Required if 'enable_metrics_server_irsa' is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_metrics_server_irsa || var.oidc_provider_arn != null
    error_message = "When 'enable_metrics_server_irsa' is true, 'oidc_provider_arn' must be provided."
  }
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster (used for IRSA). Required if 'enable_metrics_server_irsa' is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_metrics_server_irsa || var.oidc_provider_url != null
    error_message = "When 'enable_metrics_server_irsa' is true, 'oidc_provider_url' must be provided."
  }
}

variable "metrics_server_namespace" {
  description = "Kubernetes namespace where the metrics-server service account will run. Defaults to 'kube-system'."
  type        = string
  default     = "kube-system"
}

variable "metrics_server_service_account" {
  description = "Name of the Kubernetes service account for metrics-server used in IRSA binding."
  type        = string
  default     = "metrics-server"
}
