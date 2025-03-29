#########################################
# Helm Release: Fluent Bit for Container Insights
#########################################

resource "helm_release" "fluentbit" {
  name       = "fluent-bit"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"

  version          = local.fluentbit_version
  create_namespace = false

  set {
    name  = "serviceAccount.name"
    value = var.fluentbit_sa_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "cloudWatch.enabled"
    value = "true"
  }

  set {
    name  = "cloudWatch.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "cloudWatch.autoCreateGroup"
    value = "false"
  }

  set {
    name  = "cloudWatch.logGroupName"
    value = "/aws/eks/${var.cluster_name}/fluent-bit"
  }

  depends_on = [
    aws_cloudwatch_log_group.fluentbit_logs_with_prevent_destroy,
    aws_cloudwatch_log_group.fluentbit_logs_without_prevent_destroy
  ]
}
