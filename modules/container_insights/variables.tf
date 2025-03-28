variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable Container Insights for the EKS cluster. If true, sets up necessary configurations and permissions."
  type        = bool
  default     = false
}

variable "fluentbit_http_port" {
  description = "Port for Fluent Bit HTTP server"
  type        = string
  default     = "2020"
}

variable "fluentbit_read_from_head" {
  description = "Whether to read logs from the head of the file"
  type        = string
  default     = "Off"
}
