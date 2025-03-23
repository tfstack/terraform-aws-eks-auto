

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

##############################
# Local Values
##############################

locals {
  enable_metrics_server = anytrue([
    for app in var.apps : try(app.autoscaling.enabled, false)
  ])

  ignore_replica_change = {
    for app in var.apps : app.name =>
    try(app.autoscaling.enabled, false) ? ["spec[0].replicas"] : []
  }
}
