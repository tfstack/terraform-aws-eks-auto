variable "vpc" {
  description = "VPC configuration settings"
  type = object({
    id = string
    private_subnets = list(object({
      id   = string
      cidr = string
    }))
  })

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc.id))
    error_message = "The VPC ID must be in the format 'vpc-xxxxxxxxxxxxxxxxx'."
  }

  validation {
    condition     = length(var.vpc.private_subnets) > 0
    error_message = "At least one private subnet must be defined."
  }

  validation {
    condition     = alltrue([for subnet in var.vpc.private_subnets : can(regex("^subnet-[a-f0-9]+$", subnet.id))])
    error_message = "Each private subnet must have a valid subnet ID (e.g., 'subnet-xxxxxxxxxxxxxxxxx')."
  }

  validation {
    condition     = alltrue([for subnet in var.vpc.private_subnets : can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", subnet.cidr))])
    error_message = "Each subnet must have a valid CIDR block (e.g., '10.0.1.0/24')."
  }
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}

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
  }))
  default = [
    { name = "coredns" },
    { name = "kube-proxy" },
    { name = "vpc-cni" }
  ]

  validation {
    condition     = length(var.eks_addons) > 0
    error_message = "At least one EKS add-on must be specified."
  }

  validation {
    condition     = alltrue([for addon in var.eks_addons : length(setsubtract(keys(addon), ["name", "addon_version", "configuration_values", "resolve_conflicts_on_create", "resolve_conflicts_on_update", "tags", "preserve"])) == 0])
    error_message = "Each EKS add-on object must contain only the allowed attributes: 'name', 'addon_version', 'configuration_values', 'resolve_conflicts_on_create', 'resolve_conflicts_on_update', 'tags', 'preserve'."
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

variable "private_subnet_custom_tags" {
  description = "Optional custom tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  type        = string
}

variable "cluster_enabled_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = []
}

variable "cluster_compute_config" {
  description = "Compute configuration for EKS Auto Mode"
  type = object({
    node_pools = optional(list(object({
      name           = string
      instance_types = list(string)
      min_size       = number
      max_size       = number
      desired_size   = number
    })), [])
    node_role_arn = optional(string, null)
  })
  default = {}
}

variable "cluster_vpc_config" {
  description = "VPC configuration for EKS"
  type = object({
    subnet_ids              = list(string)
    security_group_ids      = list(string)
    endpoint_private_access = bool
    endpoint_public_access  = bool
    public_access_cidrs     = list(string)
  })
}

variable "cluster_encryption_config" {
  description = "Encryption configuration for Kubernetes secrets"
  type = object({
    key_arn   = string
    resources = list(string)
  })
  default = {
    key_arn   = ""
    resources = ["secrets"]
  }
}

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

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "use_existing_role" {
  description = "Set to true if using an existing IAM role for EKS"
  type        = bool
  default     = false
}

variable "existing_role_arn" {
  description = "ARN of an existing IAM role for EKS (if use_existing_role is true)"
  type        = string
  default     = ""
}

variable "cluster_enabled_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = []
}

variable "cluster_compute_config" {
  description = "Compute configuration for EKS Auto Mode"
  type = object({
    node_pools = optional(list(object({
      name           = string
      instance_types = list(string)
      min_size       = number
      max_size       = number
      desired_size   = number
    })), [])
    node_role_arn = optional(string, null)
  })
  default = {}
}

variable "cluster_vpc_config" {
  description = "VPC configuration for EKS"
  type = object({
    subnet_ids              = list(string)
    security_group_ids      = list(string)
    endpoint_private_access = bool
    endpoint_public_access  = bool
    public_access_cidrs     = list(string)
  })
}

variable "cluster_encryption_config" {
  description = "Encryption configuration for Kubernetes secrets"
  type = object({
    key_arn   = string
    resources = list(string)
  })
  default = {
    key_arn   = ""
    resources = ["secrets"]
  }
}

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

variable "tags" {
  description = "Tags to apply to the EKS cluster"
  type        = map(string)
  default     = {}
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
