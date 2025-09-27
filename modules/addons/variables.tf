variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type        = string
  default     = null
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}

variable "eks_addons" {
  description = "List of EKS add-ons to install with optional configurations"
  type = list(object({
    name                        = string
    version                     = optional(string, null)
    configuration_values        = optional(string, null)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "NONE")
    tags                        = optional(map(string), {})
    preserve                    = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for addon in var.eks_addons : length(setsubtract(keys(addon), [
        "name", "version", "configuration_values", "resolve_conflicts_on_create",
        "resolve_conflicts_on_update", "tags", "preserve"
      ])) == 0
    ])
    error_message = "Each EKS add-on object must contain only the allowed attributes."
  }

  validation {
    condition     = alltrue([for addon in var.eks_addons : addon.resolve_conflicts_on_create == "NONE" || addon.resolve_conflicts_on_create == "OVERWRITE"])
    error_message = "Valid values for 'resolve_conflicts_on_create' are 'NONE' and 'OVERWRITE'."
  }

  validation {
    condition     = alltrue([for addon in var.eks_addons : addon.resolve_conflicts_on_update == "NONE" || addon.resolve_conflicts_on_update == "OVERWRITE" || addon.resolve_conflicts_on_update == "PRESERVE"])
    error_message = "Valid values for 'resolve_conflicts_on_update' are 'NONE', 'OVERWRITE', and 'PRESERVE'."
  }
}
