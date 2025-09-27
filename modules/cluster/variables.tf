##############################
# EKS Cluster Configuration
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

variable "cluster_enabled_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = []
}

variable "cluster_node_pools" {
  description = "Node pools for EKS Auto Mode (valid: general-purpose, system)"
  type        = list(string)
  default     = ["general-purpose", "system"]

  validation {
    condition     = alltrue([for pool in var.cluster_node_pools : contains(["general-purpose", "system"], pool)])
    error_message = "Valid values for cluster_node_pools are: 'general-purpose' and 'system'."
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

##############################
# IAM & Roles
##############################

variable "eks_auto_cluster_role_arn" {
  description = "Optional. Provide an existing IAM role ARN for EKS Fargate. If not set, a new role will be created."
  type        = string
  default     = null

  validation {
    condition     = var.eks_auto_cluster_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.eks_auto_cluster_role_arn))
    error_message = "If provided, the value must be a valid IAM role ARN (e.g., arn:aws:iam::123456789012:role/MyFargateRole)."
  }
}

variable "eks_auto_node_role_arn" {
  description = "ARN of an existing IAM role for EKS worker nodes (e.g., from a node group or auto scaling group)."
  type        = string
  default     = null

  validation {
    condition     = var.eks_auto_node_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.eks_auto_node_role_arn))
    error_message = "You must provide a valid, non-empty IAM role ARN (e.g., arn:aws:iam::123456789012:role/NodeInstanceRole)."
  }
}

##############################
# Networking
##############################

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "The VPC ID must be in the format 'vpc-xxxxxxxxxxxxxxxxx'."
  }
}

variable "create_security_group" {
  description = "Whether to create an internal security group for EKS"
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
    service_cidr            = optional(string, "172.20.0.0/16")
  })
}

##############################
# Optional Features
##############################

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

variable "enable_oidc" {
  description = "Enable IAM Roles for Service Accounts (IRSA) support by creating the OIDC provider for the EKS cluster."
  type        = bool
  default     = false
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an existing OIDC provider to use instead of creating a new one"
  type        = string
  default     = null

  validation {
    condition     = var.existing_oidc_provider_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/.+", var.existing_oidc_provider_arn))
    error_message = "If provided, the value must be a valid OIDC provider ARN (e.g., arn:aws:iam::123456789012:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E)."
  }
}

variable "enable_container_insights" {
  description = "Whether to enable CloudWatch logging for EKS workloads (e.g., Fluent Bit, Fargate logs)"
  type        = bool
  default     = false
}

##############################
# Kubernetes API Wait (Post-Creation)
##############################

variable "enable_k8s_api_wait" {
  description = "If true, wait for Kubernetes API to become ready before continuing"
  type        = bool
  default     = true
}

variable "k8s_api_wait_attempts" {
  description = "Number of retry attempts when waiting for Kubernetes API"
  type        = number
  default     = 30
}

variable "k8s_api_wait_interval" {
  description = "Seconds to wait between each retry attempt"
  type        = number
  default     = 5
}

##############################
# CloudWatch Logging
##############################

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
# Metadata
##############################

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}
