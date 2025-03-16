#########################################
# EBS CSI Controller Module Variables
#########################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_ebs_csi_controller" {
  description = "Enable the AWS EBS CSI Controller. If true, deploys the Helm release and sets up required IAM roles and policies."
  type        = bool
  default     = false
}

variable "ebs_csi_controller_sa_name" {
  description = "The name of the Kubernetes ServiceAccount used by the EBS CSI driver"
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA integration with the EBS CSI controller"
  type        = string
  default     = null

  validation {
    condition     = var.oidc_provider_arn != null
    error_message = "'oidc_provider_arn' is required for setting up IRSA for the EBS CSI controller."
  }
}

variable "oidc_provider_url" {
  description = "OIDC provider URL for IRSA integration with the EBS CSI controller"
  type        = string
  default     = null

  validation {
    condition     = var.oidc_provider_url != null
    error_message = "'oidc_provider_url' is required for setting up IRSA for the EBS CSI controller."
  }
}

variable "ebs_csi_driver_chart_version" {
  description = "Helm chart version to use for AWS EBS CSI Driver. Use 'latest' or null to always get the latest chart version."
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
