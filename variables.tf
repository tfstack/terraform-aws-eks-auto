#########################################
# EKS Cluster Core Configuration
#########################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "latest"
}

variable "cluster_enabled_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = []
}

variable "cluster_node_pools" {
  description = "Node pools for EKS Auto Mode (valid: general-purpose, system)"
  type        = list(string)
  default     = ["general-purpose"]

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

#########################################
# VPC and Networking
#########################################

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "The VPC ID must be in the format 'vpc-xxxxxxxxxxxxxxxxx'."
  }
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
  })
}

variable "create_security_group" {
  description = "Whether to create an internal security group for EKS"
  type        = bool
  default     = true
}

#########################################
# Optional Features & IAM
#########################################

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
  default     = true
}

variable "enable_ebs_csi_controller" {
  description = "Enable the AWS EBS CSI Controller. If true, deploys the Helm release and sets up required IAM roles and policies."
  type        = bool
  default     = false
}

#########################################
# Logging and Observability
#########################################

variable "enable_container_insights" {
  description = "Whether to enable CloudWatch logging for EKS workloads (e.g., Fluent Bit, Fargate logs)"
  type        = bool
  default     = false
}

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

variable "enable_prometheus" {
  description = "Enable Prometheus deployment to the EKS cluster"
  type        = bool
  default     = false
}

variable "prometheus_chart_version" {
  description = "Helm chart version to use for Prometheus. Use \"latest\" or null to always get the latest chart version."
  type        = string
  default     = "latest"
}

#########################################
# Storage - EBS CSI Driver
#########################################

variable "ebs_csi_controller_sa_name" {
  description = "The name of the Kubernetes ServiceAccount used by the EBS CSI driver"
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "ebs_csi_driver_chart_version" {
  description = "Helm chart version to use for AWS EBS CSI Driver. Use 'latest' or null to always get the latest chart version."
  type        = string
  default     = "latest"
}

#########################################
# Container Insights - Fluent Bit
#########################################

variable "fluentbit_namespace" {
  description = "The Kubernetes namespace where Fluent Bit is deployed. Use 'aws-observability' for EKS Auto Mode or 'amazon-cloudwatch' for standard EKS."
  type        = string
  default     = "aws-observability"
}

variable "fluentbit_sa_name" {
  description = "The name of the Kubernetes service account used by Fluent Bit. This is used to associate the IAM role via IRSA."
  type        = string
  default     = "fluent-bit"
}

#########################################
# Namespaces and Add-ons
#########################################

variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ns in var.namespaces : !contains([
        "default",
        "kube-system",
        "kube-public",
        "kube-node-lease"
      ], ns)
    ])
    error_message = "The following namespaces are managed by Kubernetes and cannot be created: default, kube-system, kube-public, kube-node-lease"
  }
}

variable "eks_addons" {
  description = "List of EKS add-ons to install with optional configurations"
  type = list(object({
    name                        = string
    version                     = optional(string, null)
    configuration_values        = optional(string, null)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "NONE")
    tags                        = optional(map(string), {})
    preserve                    = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for addon in var.eks_addons : length(setsubtract(keys(addon), [
        "name", "version", "configuration_values", "resolve_conflicts_on_create",
        "resolve_conflicts_on_update", "tags", "preserve"
      ])) == 0
    ])
    error_message = "Each EKS add-on object must contain only the allowed attributes."
  }

  validation {
    condition     = alltrue([for addon in var.eks_addons : addon.resolve_conflicts_on_create == "NONE" || addon.resolve_conflicts_on_create == "OVERWRITE"])
    error_message = "Valid values for 'resolve_conflicts_on_create' are 'NONE' and 'OVERWRITE'."
  }

  validation {
    condition     = alltrue([for addon in var.eks_addons : addon.resolve_conflicts_on_update == "NONE" || addon.resolve_conflicts_on_update == "OVERWRITE" || addon.resolve_conflicts_on_update == "PRESERVE"])
    error_message = "Valid values for 'resolve_conflicts_on_update' are 'NONE', 'OVERWRITE', and 'PRESERVE'."
  }
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller with IAM role and RBAC"
  type        = bool
  default     = false
}

#########################################
# Workloads
#########################################

variable "workloads" {
  description = "List of workloads to deploy"
  type = list(object({
    name             = string
    namespace        = string
    replicas         = optional(number, 1)
    labels           = optional(map(string), {})
    create_namespace = optional(bool, false)
    namespace_metadata = optional(object({
      labels      = optional(map(string), {})
      annotations = optional(map(string), {})
    }), {})
    service_account_name = optional(string, null)
    irsa = optional(object({
      enabled     = bool
      policy_arns = optional(list(string), [])
      }), {
      enabled     = false
      policy_arns = []
    })
    containers = optional(list(object({
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
    })), [])
    init_containers = optional(list(object({
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
    })), [])
    volumes = optional(list(object({
      name = string
      config_map = optional(object({
        name = string
      }), null)
      secret = optional(object({
        secret_name = string
      }), null)
    })), [])
    configmaps = optional(list(object({
      name = string
      data = map(string)
    })), [])
    create_service = optional(bool, true)
    service_type   = optional(string, "ClusterIP")
    service_ports = optional(list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = optional(string, "TCP")
    })), [])
    service_annotations = optional(map(string), {})
    create_ingress      = optional(bool, false)
    ingress_scheme      = optional(string, "internet-facing")
    ingress_protocol    = optional(string, "http")
    ingress_annotations = optional(map(string), {})
    ingress_rules = optional(list(object({
      host = string
      http_paths = list(object({
        path         = string
        path_type    = optional(string, "Prefix")
        backend_port = number
      }))
    })), [])
    logging = optional(object({
      enabled = bool
      }), {
      enabled = false
    })
    tags = optional(map(string), {})
  }))
  default = []
}

#########################################
# Helm Chart Management
#########################################

variable "helm_charts" {
  description = "List of Helm releases to deploy"
  type = list(object({
    name                 = string
    namespace            = string
    repository           = string
    chart                = string
    chart_version        = optional(string)
    values_files         = optional(list(string), [])
    set_values           = optional(list(object({ name = string, value = string })), [])
    set_sensitive_values = optional(list(object({ name = string, value = string })), [])
    create_namespace     = optional(bool, true)
    enabled              = optional(bool, true)
    depends_on           = optional(list(any), [])
  }))
  default = []
}

#########################################
# App Deployments
#########################################

variable "apps" {
  type = list(object({
    name           = string
    image          = string
    port           = number
    namespace      = optional(string, "default")
    labels         = optional(map(string), {})
    enable_logging = optional(bool, false)
    replicas       = optional(number, 1)
    autoscaling    = optional(object({ enabled = bool }), { enabled = false })
    resources      = optional(object({ limits = optional(map(string)), requests = optional(map(string)) }), null)
    env            = optional(list(object({ name = string, value = string })), [])
    healthcheck = optional(object({
      liveness = optional(object({
        http_get              = object({ path = string, port = number })
        initial_delay_seconds = number
        period_seconds        = number
      }))
      readiness = optional(object({
        http_get              = object({ path = string, port = number })
        initial_delay_seconds = number
        period_seconds        = number
      }))
    }), { liveness = null, readiness = null })
    volume_mounts = optional(list(object({ name = string, mount_path = string })), [])
    volumes = optional(list(object({
      name                    = string
      persistent_volume_claim = object({ claim_name = string })
    })), [])
    init_containers = optional(list(object({ name = string, image = string, command = list(string) })), [])
    node_selector   = optional(map(string), {})
    tolerations = optional(list(object({
      key      = string
      operator = optional(string, "Equal")
      value    = optional(string)
      effect   = optional(string)
    })), [])
    image_pull_secrets = optional(list(string), [])
    pod_annotations    = optional(map(string), {})
    security_context = optional(object({
      run_as_user  = optional(number)
      run_as_group = optional(number)
      fs_group     = optional(number)
    }), null)
  }))
  default = []
}

#########################################
# EKS View Access Role Binding
#########################################

variable "eks_view_access" {
  description = "Configuration for assigning view access to EKS cluster"
  type = object({
    enabled    = bool
    role_names = list(string)
  })
  default = {
    enabled    = false
    role_names = []
  }

  validation {
    condition     = alltrue([for name in var.eks_view_access.role_names : can(regex("^[a-zA-Z0-9+=,.@_-]{1,128}$", name))])
    error_message = "Each role name must be a valid IAM role name (1-128 characters, matching IAM naming rules)."
  }
}

#########################################
# Common Metadata
#########################################

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}
