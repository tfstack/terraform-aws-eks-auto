

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "The VPC ID must be in the format 'vpc-xxxxxxxxxxxxxxxxx'."
  }
}

variable "cluster_vpc_config" {
  description = "VPC configuration for EKS"
  type = object({
    private_subnet_ids      = list(string)
    private_access_cidrs    = list(string)
    public_access_cidrs     = list(string)
    security_group_ids      = list(string)
    endpoint_private_access = bool
    endpoint_public_access  = bool
  })
}

variable "create_security_group" {
  description = "Whether to create an internal security group for EKS"
  type        = bool
  default     = true
}

variable "enable_cluster_encryption" {
  description = "Enable encryption for Kubernetes secrets using a KMS key"
  type        = bool
  default     = false
}

variable "enable_elastic_load_balancing" {
  description = "Enable or disable Elastic Load Balancing for EKS Auto Mode"
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = []
}

##############################
# Variables: EKS Add-ons & Fargate
##############################

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

variable "fargate_profiles" {
  description = "Fargate profiles for EKS Auto Mode"
  type = map(object({
    enabled   = bool
    namespace = string
    labels    = optional(map(string), {})
  }))
  default = {
    default = {
      enabled   = true
      namespace = "default"
    },
    logging = {
      enabled   = false
      namespace = "logging"
    },
    monitoring = {
      enabled   = false
      namespace = "monitoring"
    }
    kube_system = {
      enabled   = false
      namespace = "kube_system"
    }
  }
}

##############################
# Variables: Cluster Upgrades & Networking
##############################

variable "cluster_upgrade_policy" {
  description = "Upgrade policy for EKS cluster"
  type = object({
    support_type = optional(string, null)
  })
  default = {}
}

variable "cluster_zonal_shift_config" {
  description = "Zonal shift configuration"
  type = object({
    enabled = optional(bool, false)
  })
  default = {}
}

variable "timeouts" {
  description = "Timeouts for EKS cluster creation, update, and deletion"
  type = object({
    create = optional(string, null)
    update = optional(string, null)
    delete = optional(string, null)
  })
  default = {}
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}

##############################
# Variables: App Workloads & Access
##############################

variable "node_pools" {
  description = "Node pools for EKS Auto Mode (valid: general-purpose, system)"
  type        = list(string)
  default     = ["general-purpose"]

  validation {
    condition     = alltrue([for pool in var.node_pools : contains(["general-purpose", "system"], pool)])
    error_message = "Valid values for node_pools are: 'general-purpose' and 'system'."
  }
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

##############################
# Variables: Metrics Server
##############################

variable "metrics_server" {
  description = "Configuration for the Kubernetes Metrics Server Helm release"
  type = object({
    version = string
    resources = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    version = "3.12.2"
    resources = {
      cpu    = "100m"
      memory = "200Mi"
    }
  }
}
