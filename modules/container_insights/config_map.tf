#########################################
# Fluent Bit Cluster Info ConfigMap
#########################################

resource "kubernetes_config_map" "fluent_bit_cluster_info" {
  count = var.enable_container_insights ? 1 : 0

  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = "amazon-cloudwatch"
  }

  data = {
    "cluster.name" = var.cluster_name
    "http.server"  = var.fluentbit_http_port == "" ? "Off" : "On"
    "http.port"    = var.fluentbit_http_port != "" ? var.fluentbit_http_port : null
    "read.head"    = var.fluentbit_read_from_head
    "read.tail"    = var.fluentbit_read_from_head == "On" ? "Off" : "On"
    "logs.region"  = data.aws_region.current.name
  }
}
