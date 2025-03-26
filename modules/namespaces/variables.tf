variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
}

variable "executor_dependency" {
  description = "Dummy input to establish a dependency on the executor module"
  type        = string
  default     = null
}
