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
