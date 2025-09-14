##############################
# ConfigMap: Fluent Bit Logging Configuration
##############################

resource "kubernetes_config_map" "aws_logging" {
  metadata {
    name      = "aws-logging"
    namespace = var.aws_observability_namespace
  }

  data = {
    flb_log_cw = "false"

    "filters.conf" = <<-EOT
      [FILTER]
          Name parser
          Match logging-enabled.*
          Key_name log
          Parser crio

      [FILTER]
          Name kubernetes
          Match logging-enabled.*
          Merge_Log On
          Keep_Log Off
          Buffer_Size 0
          Kube_Meta_Cache_TTL 300s
    EOT

    "output.conf" = <<-EOT
      [OUTPUT]
          Name cloudwatch_logs
          Match logging-enabled.*
          region ${data.aws_region.current.region}
          log_group_name /aws/eks/${var.cluster_name}/logs
          log_stream_prefix from-fluent-bit-
          log_retention_days ${var.eks_log_retention_days}
          auto_create_group true
    EOT

    "parsers.conf" = <<-EOT
      [PARSER]
          Name crio
          Format Regex
          Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
          Time_Key    time
          Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    EOT
  }
}
