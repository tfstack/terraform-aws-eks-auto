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
