#########################################
# Variable: Kubernetes Namespaces
#########################################

variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ns in var.namespaces : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", ns))
    ])
    error_message = "Namespace names must be valid Kubernetes names (lowercase alphanumeric characters and hyphens only, starting and ending with alphanumeric)."
  }

  validation {
    condition     = length(var.namespaces) == length(distinct(var.namespaces))
    error_message = "Namespace names must be unique."
  }
}

variable "namespace_labels" {
  description = "Labels to apply to all created namespaces"
  type        = map(string)
  default     = {}
}

variable "namespace_annotations" {
  description = "Annotations to apply to all created namespaces"
  type        = map(string)
  default     = {}
}
