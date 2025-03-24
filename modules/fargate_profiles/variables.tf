variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable monitoring components like CloudWatch or Prometheus"
  type        = bool
  default     = false
}

variable "enable_kube_system" {
  description = "Enable resources or behaviors specific to the kube-system namespace"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Enable EKS control plane logging or other log collection features"
  type        = bool
  default     = false
}

variable "eks_fargate_role_arn" {
  description = "Optional. Provide an existing IAM role ARN for EKS Fargate. If not set, a new role will be created."
  type        = string

  validation {
    condition     = var.eks_fargate_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.eks_fargate_role_arn))
    error_message = "If provided, the value must be a valid IAM role ARN (e.g., arn:aws:iam::123456789012:role/MyFargateRole)."
  }
}

variable "profiles_name" {
  description = "List of EKS Fargate profile names to be created"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch resources into (e.g., EKS cluster, node groups, etc)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0 && alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "You must provide a non-empty list of valid subnet IDs (e.g., subnet-abc123)."
  }
}
