resource "kubernetes_namespace" "this" {
  for_each = {
    for app in var.apps :
    coalesce(app.namespace, "default") => app
    if lookup(app, "create_namespace", true)
    && !contains(["default", "kube-system", "kube-public", "kube-node-lease"], coalesce(app.namespace, "default"))
  }

  metadata {
    name = each.key
  }
}

resource "kubernetes_deployment" "this" {
  for_each = { for app in var.apps : app.name => app }

  metadata {
    name      = each.key
    namespace = each.value.namespace
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
      }

      spec {
        container {
          name  = each.key
          image = each.value.image

          port {
            container_port = each.value.port
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.this
  ]
}
