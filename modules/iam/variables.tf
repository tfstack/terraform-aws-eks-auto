##############################
# Variables: EKS Cluster Configuration
##############################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
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
