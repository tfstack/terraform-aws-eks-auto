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
