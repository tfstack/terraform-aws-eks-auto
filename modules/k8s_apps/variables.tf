#########################################
# Variable: Application Deployment Configuration
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

    resources = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }), null)

    env = optional(list(object({
      name  = string
      value = string
    })), [])

    healthcheck = optional(object({
      liveness = optional(object({
        http_get = object({
          path = string
          port = number
        })
        initial_delay_seconds = number
        period_seconds        = number
      }))
      readiness = optional(object({
        http_get = object({
          path = string
          port = number
        })
        initial_delay_seconds = number
        period_seconds        = number
      }))
    }), { liveness = null, readiness = null })

    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])

    volumes = optional(list(object({
      name = string
      persistent_volume_claim = object({
        claim_name = string
      })
    })), [])

    init_containers = optional(list(object({
      name    = string
      image   = string
      command = list(string)
    })), [])

    node_selector = optional(map(string), {})

    tolerations = optional(list(object({
      key      = string
      operator = optional(string, "Equal")
      value    = optional(string)
      effect   = optional(string)
    })), [])

    image_pull_secrets = optional(list(string), [])

    pod_annotations = optional(map(string), {})

    security_context = optional(object({
      run_as_user  = optional(number)
      run_as_group = optional(number)
      fs_group     = optional(number)
    }), null)
  }))
  default = []
}
