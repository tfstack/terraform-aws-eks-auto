##############################
# Variables: EKS Cluster Configuration
##############################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "latest"
}

variable "apps" {
  description = "List of Kubernetes apps"
  type = list(object({
    name             = string
    image            = string
    port             = number
    namespace        = optional(string, "default")
    labels           = optional(map(string), {})
    create_namespace = optional(bool, true)
    enable_logging   = optional(bool, false)

    autoscaling = optional(object({
      enabled                           = bool
      min_replicas                      = number
      max_replicas                      = number
      target_cpu_utilization_percentage = number
    }))
  }))
  default = []
}

variable "eks_view_access" {
  description = "Configuration for assigning view access to EKS cluster"
  type = object({
    enabled    = bool
    role_names = list(string)
  })
  default = {
    enabled    = false
    role_names = []
  }

  validation {
    condition     = alltrue([for name in var.eks_view_access.role_names : can(regex("^[a-zA-Z0-9+=,.@_-]{1,128}$", name))])
    error_message = "Each role name must be a valid IAM role name (1-128 characters, matching IAM naming rules)."
  }
}

variable "enable_executor_cluster_admin" {
  description = "Whether to grant AmazonEKSClusterAdminPolicy to the IAM role running Terraform"
  type        = bool
  default     = false
}
