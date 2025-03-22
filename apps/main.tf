resource "kubernetes_namespace" "this" {
  for_each = {
    for app in var.apps :
    coalesce(app.namespace, "default") => app
    if lookup(app, "create_namespace", true)
    && !contains(["default", "kube-system", "kube-public", "kube-node-lease"], coalesce(app.namespace, "default"))
  }

  metadata {
    name = each.key

    annotations = merge(
      {
        "eks.amazonaws.com/compute-type" = "fargate"
      },
      lookup(each.value, "enable_logging", false) ? {
        "eks.amazonaws.com/enable-logging" = "true"
        } : {
        "eks.amazonaws.com/enable-logging" = "false"
      }
    )
  }
}

resource "kubernetes_deployment" "this" {
  for_each = { for app in var.apps : app.name => app }

  metadata {
    name      = each.key
    namespace = coalesce(each.value.namespace, "default")
    labels    = merge({ app = each.key }, each.value.labels)
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
        labels = {
          app = each.key
        }

        annotations = merge(
          {},
          lookup(each.value, "enable_logging", false) ? {
            "eks.amazonaws.com/enable-logging" = "true"
            } : {
            "eks.amazonaws.com/enable-logging" = "false"
          }
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

  depends_on = [
    kubernetes_namespace.this
  ]
}
