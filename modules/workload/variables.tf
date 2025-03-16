#########################################
# Workload Module Variables
#########################################

variable "name" {
  description = "Name of the workload"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the workload"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 1
}

variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "namespace_metadata" {
  description = "Metadata for the namespace (labels and annotations)"
  type = object({
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  })
  default = {}
}

variable "service_account_name" {
  description = "Name of the service account (defaults to workload name if not specified)"
  type        = string
  default     = null
}

variable "irsa" {
  description = "IRSA configuration for the workload"
  type = object({
    enabled           = bool
    oidc_provider_arn = string
    policy_arns       = optional(list(string), [])
  })
  default = {
    enabled           = false
    oidc_provider_arn = ""
    policy_arns       = []
  }
}

variable "containers" {
  description = "List of containers for the workload"
  type = list(object({
    name    = string
    image   = string
    command = optional(list(string), null)
    args    = optional(list(string), null)
    env = optional(list(object({
      name  = string
      value = string
    })), [])
    resources = optional(object({
      limits   = optional(map(string), {})
      requests = optional(map(string), {})
    }), null)
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
  default = []
}

variable "init_containers" {
  description = "List of init containers for the workload"
  type = list(object({
    name    = string
    image   = string
    command = optional(list(string), null)
    args    = optional(list(string), null)
    env = optional(list(object({
      name  = string
      value = string
    })), [])
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
  default = []
}

variable "volumes" {
  description = "List of volumes for the workload"
  type = list(object({
    name = string
    config_map = optional(object({
      name = string
    }), null)
    secret = optional(object({
      secret_name = string
    }), null)
  }))
  default = []
}

variable "configmaps" {
  description = "List of ConfigMaps for the workload"
  type = list(object({
    name = string
    data = map(string)
  }))
  default = []
}

variable "create_service" {
  description = "Whether to create a Kubernetes service"
  type        = bool
  default     = true
}

variable "service_type" {
  description = "Type of Kubernetes service"
  type        = string
  default     = "ClusterIP"
}

variable "service_ports" {
  description = "List of ports for the service"
  type = list(object({
    name        = string
    port        = number
    target_port = number
    protocol    = optional(string, "TCP")
  }))
  default = []
}

variable "service_annotations" {
  description = "Annotations for the service"
  type        = map(string)
  default     = {}
}

variable "logging" {
  description = "Logging configuration for the workload"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "create_ingress" {
  description = "Whether to create an Ingress resource"
  type        = bool
  default     = false
}

variable "ingress_scheme" {
  description = "ALB scheme - 'internet-facing' for external or 'internal' for internal"
  type        = string
  default     = "internet-facing"
  validation {
    condition     = contains(["internet-facing", "internal"], var.ingress_scheme)
    error_message = "ingress_scheme must be either 'internet-facing' or 'internal'."
  }
}

variable "ingress_protocol" {
  description = "Protocol for the ALB URL - 'http' or 'https'"
  type        = string
  default     = "http"
  validation {
    condition     = contains(["http", "https"], var.ingress_protocol)
    error_message = "ingress_protocol must be either 'http' or 'https'."
  }
}

variable "ingress_annotations" {
  description = "Annotations for the Ingress resource"
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "Rules for the Ingress resource"
  type = list(object({
    host = string
    http_paths = list(object({
      path         = string
      path_type    = optional(string, "Prefix")
      backend_port = number
    }))
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
