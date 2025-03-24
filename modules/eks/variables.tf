##############################
# Variables: EKS Cluster Configuration
##############################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = <<EOF
EKS Kubernetes version

Optional. Use:
- A specific version (e.g. "1.29") to pin the cluster version
- "latest" or null to let EKS use the latest version at creation
EOF
  type        = string
  default     = null
}

variable "eks_fargate_role_arn" {
  description = "Optional. Provide an existing IAM role ARN for EKS Fargate. If not set, a new role will be created."
  type        = string

  validation {
    condition     = var.eks_fargate_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.eks_fargate_role_arn))
    error_message = "If provided, the value must be a valid IAM role ARN (e.g., arn:aws:iam::123456789012:role/MyFargateRole)."
  }
}

variable "cluster_enabled_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = []
}

variable "cluster_node_pools" {
  description = "Node pools for EKS Auto Mode (valid: general-purpose, system)"
  type        = list(string)
  default     = ["general-purpose"]

  validation {
    condition     = alltrue([for pool in var.cluster_node_pools : contains(["general-purpose", "system"], pool)])
    error_message = "Valid values for cluster_node_pools are: 'general-purpose' and 'system'."
  }
}

variable "eks_auto_nodes_role_arn" {
  description = "ARN of an existing IAM role for EKS worker nodes (e.g., from a node group or auto scaling group)."
  type        = string

  validation {
    condition     = length(var.eks_auto_nodes_role_arn) > 0 && can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.eks_auto_nodes_role_arn))
    error_message = "You must provide a valid, non-empty IAM role ARN (e.g., arn:aws:iam::123456789012:role/NodeInstanceRole)."
  }
}

variable "create_security_group" {
  description = "Whether to create an internal security group for EKS"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "The VPC ID must be in the format 'vpc-xxxxxxxxxxxxxxxxx'."
  }
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
