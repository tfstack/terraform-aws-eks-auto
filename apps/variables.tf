variable "apps" {
  description = "List of Kubernetes apps to deploy"
  type = list(object({
    name      = string
    namespace = optional(string, "default")
    image     = string
    port      = optional(number, 80)
    labels    = optional(map(string), {})
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
