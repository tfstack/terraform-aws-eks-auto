#########################################
# Container Insights Variables for Fluent Bit
#########################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable Container Insights for the EKS cluster. If true, sets up necessary configurations and permissions."
  type        = bool
  default     = false
}

variable "fluentbit_http_port" {
  description = "Port for Fluent Bit HTTP server"
  type        = string
  default     = "2020"
}

variable "fluentbit_read_from_head" {
  description = "Whether to read logs from the head of the file"
  type        = string
  default     = "Off"
}

variable "fluentbit_sa_namespace" {
  description = "The Kubernetes namespace where the Fluent Bit service account is deployed. Used to define the IRSA trust relationship."
  type        = string
  default     = "amazon-cloudwatch"
}

variable "fluentbit_sa_name" {
  description = "The name of the Kubernetes service account used by Fluent Bit. This is used to associate the IAM role via IRSA."
  type        = string
  default     = "fluent-bit"
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS cluster (used for IRSA). Required if 'enable_container_insights' is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_container_insights || var.oidc_provider_arn != null
    error_message = "When 'enable_container_insights' is true, 'oidc_provider_arn' must be provided."
  }
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster (used for IRSA). Required if 'enable_container_insights' is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_container_insights || var.oidc_provider_url != null
    error_message = "When 'enable_container_insights' is true, 'oidc_provider_url' must be provided."
  }
}

variable "fluentbit_chart_version" {
  description = "Helm chart version to use. Use \"latest\" or null to always get the latest chart version."
  type        = string
  default     = "latest"
}

variable "eks_log_prevent_destroy" {
  description = "Whether to prevent the destruction of the CloudWatch log group"
  type        = bool
  default     = true
}

variable "eks_log_retention_days" {
  description = "The number of days to retain logs for the EKS in CloudWatch"
  type        = number
  default     = 30
}
