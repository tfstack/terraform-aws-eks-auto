







##############################
# Variables: EKS Add-ons & Fargate
##############################




##############################
# Variables: Cluster Upgrades & Networking
##############################






##############################
# Variables: App Workloads & Access
##############################


variable "enable_executor_cluster_admin" {
  description = "Whether to grant AmazonEKSClusterAdminPolicy to the IAM role running Terraform"
  type        = bool
  default     = false
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
