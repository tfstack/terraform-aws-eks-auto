variable "apps" {
  description = "List of Kubernetes apps to deploy"
  type = list(object({
    name             = string
    image            = string
    port             = number
    namespace        = optional(string, "default")
    labels           = optional(map(string), {})
    create_namespace = optional(bool, true)
    enable_logging   = optional(bool, false)
  }))
}

variable "cluster_name" {
  description = "EKS cluster name (not used directly but helpful for tracking/logging)"
  type        = string
}

variable "cluster_endpoint" {
  description = "The EKS cluster endpoint"
  type        = string
}

variable "cluster_ca" {
  description = "Base64 encoded cluster CA certificate"
  type        = string
}
