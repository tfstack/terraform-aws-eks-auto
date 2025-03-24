







##############################
# Variables: EKS Add-ons & Fargate
##############################



variable "fargate_profiles" {
  description = "Fargate profiles for EKS Auto Mode"
  type = map(object({
    enabled   = bool
    namespace = string
    labels    = optional(map(string), {})
  }))
  default = {
    default = {
      enabled   = true
      namespace = "default"
    },
    logging = {
      enabled   = false
      namespace = "logging"
    },
    monitoring = {
      enabled   = false
      namespace = "monitoring"
    }
    kube_system = {
      enabled   = false
      namespace = "kube_system"
    }
  }
}

##############################
# Variables: Cluster Upgrades & Networking
##############################

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
