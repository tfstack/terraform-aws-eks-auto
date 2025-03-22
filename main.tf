data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

locals {
  enable_cloudwatch_logging = length([
    for app in var.apps : app
    if try(app.enable_logging, false)
  ]) > 0
}
