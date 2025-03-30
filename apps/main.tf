
##############################
# Kubernetes HPA for Apps
##############################

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  for_each = {
    for app in var.apps : app.name => app
    if try(app.autoscaling.enabled, false)
  }

  metadata {
    name      = each.key
    namespace = coalesce(each.value.namespace, "default")
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = each.key
    }

    min_replicas = each.value.autoscaling.min_replicas
    max_replicas = each.value.autoscaling.max_replicas

    metric {
      type = "Resource"

      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = each.value.autoscaling.target_cpu_utilization_percentage
        }
      }
    }
  }
}
