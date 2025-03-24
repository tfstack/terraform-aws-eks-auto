variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_addons" {
  description = "List of EKS add-ons to install with optional configurations"
  type = list(object({
    name                        = string
    addon_version               = optional(string, null)
    configuration_values        = optional(string, null)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "NONE")
    tags                        = optional(map(string), {})
    preserve                    = optional(bool, false)
    fargate_required            = optional(bool, false)
    namespace                   = optional(string, "kube-system")
    label_override              = optional(string, null)
  }))
  default = [
    { name = "kube-proxy", addon_version = "v1.32.0-eksbuild.2" },
    { name = "vpc-cni", addon_version = "v1.19.2-eksbuild.5" }
  ]

  validation {
    condition     = length(var.eks_addons) > 0
    error_message = "At least one EKS add-on must be specified."
  }

  validation {
    condition = alltrue([
      for addon in var.eks_addons : length(setsubtract(keys(addon), [
        "name", "addon_version", "configuration_values", "resolve_conflicts_on_create",
        "resolve_conflicts_on_update", "tags", "preserve", "fargate_required",
        "namespace", "label_override"
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
