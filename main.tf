##############################
# AWS Data Sources
##############################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

##############################
# Local Values
##############################

locals {
  enable_cloudwatch_logging = length([
    for app in var.apps : app
    if try(app.enable_logging, false)
  ]) > 0

  enable_metrics_server = anytrue([
    for app in var.apps : try(app.autoscaling.enabled, false)
  ])
}
