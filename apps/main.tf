##############################
# Kubernetes Namespace for Apps
##############################

resource "kubernetes_namespace" "this" {
  for_each = {
    for app in var.apps :
    coalesce(app.namespace, "default") => app
    if lookup(app, "create_namespace", true)
    && !contains(["default", "kube-system", "kube-public", "kube-node-lease"], coalesce(app.namespace, "default"))
  }

  metadata {
    name = each.key

    annotations = {
      "eks.amazonaws.com/compute-type" = "fargate"
    }
  }
}

##############################
# Kubernetes Deployment for Apps
##############################

resource "kubernetes_deployment" "this" {
  for_each = { for app in var.apps : app.name => app }

  metadata {
    name      = each.key
    namespace = coalesce(each.value.namespace, "default")
    labels = merge(
      { app = each.key },
      lookup(each.value, "labels", {})
    )
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = each.key
      }
    }

    template {
      metadata {
        labels = merge(
          { app = each.key },
          lookup(each.value, "labels", {})
        )

        annotations = merge(
          {
            "eks.amazonaws.com/enable-logging" = each.value.enable_logging ? "true" : "false"
          },
          each.value.enable_logging ? {
            "fluentbit.io/tag" = "logging-enabled.${each.key}"
          } : {}
        )
      }

      spec {
        container {
          name  = each.key
          image = each.value.image

          port {
            container_port = each.value.port
          }

          dynamic "liveness_probe" {
            for_each = try([each.value.healthcheck.liveness], [])
            content {
              http_get {
                path = liveness_probe.value.http_get.path
                port = liveness_probe.value.http_get.port
              }
              initial_delay_seconds = liveness_probe.value.initial_delay_seconds
              period_seconds        = liveness_probe.value.period_seconds
            }
          }

          dynamic "readiness_probe" {
            for_each = try([each.value.healthcheck.readiness], [])
            content {
              http_get {
                path = readiness_probe.value.http_get.path
                port = readiness_probe.value.http_get.port
              }
              initial_delay_seconds = readiness_probe.value.initial_delay_seconds
              period_seconds        = readiness_probe.value.period_seconds
            }
          }
        }
      }
    }
  }
}

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
