#########################################
# Helm Release: Fluent Bit for Container Insights
#########################################

resource "helm_release" "fluentbit" {
  count = var.enable_container_insights ? 1 : 0

  name       = "fluent-bit"
  namespace  = var.fluentbit_namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = local.fluentbit_version

  # Robust installs/upgrades
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600
  recreate_pods    = false
  create_namespace = false # Namespace must be created/managed outside (esp. in Auto Mode)

  # Use an existing ServiceAccount with IRSA annotation applied outside Helm
  set = [
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = var.fluentbit_sa_name
    },
    {
      name  = "cloudWatch.enabled"
      value = "true"
    },
    {
      name  = "cloudWatch.region"
      value = data.aws_region.current.region
    },
    {
      name  = "cloudWatch.autoCreateGroup"
      value = "false"
    },
    {
      name  = "cloudWatch.logGroupName"
      value = "/aws/eks/${var.cluster_name}/fluent-bit"
    },
    {
      name  = "cloudWatch.logStreamPrefix"
      value = "fluent-bit"
    },
    {
      name  = "kinesis.enabled"
      value = "false"
    },
    {
      name  = "firehose.enabled"
      value = "false"
    },
    {
      name  = "elasticsearch.enabled"
      value = "false"
    }
  ]

  depends_on = [
    aws_cloudwatch_log_group.fluentbit_logs_with_prevent_destroy,
    aws_cloudwatch_log_group.fluentbit_logs_without_prevent_destroy
  ]
}
