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
}
