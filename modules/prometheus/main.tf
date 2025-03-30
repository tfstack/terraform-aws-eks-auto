locals {
  prometheus_version = (
    var.prometheus_chart_version == null || var.prometheus_chart_version == "latest"
  ) ? null : var.prometheus_chart_version
}
