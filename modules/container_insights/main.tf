#########################################
# Fluent Bit Version Resolver
#########################################

data "aws_region" "current" {}

locals {
  fluentbit_version = (
    var.fluentbit_chart_version == null || var.fluentbit_chart_version == "latest"
  ) ? null : var.fluentbit_chart_version
}
