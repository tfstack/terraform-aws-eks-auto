#########################################
# Kubernetes Deployment for Applications
#########################################

resource "kubernetes_deployment" "this" {
  for_each = { for app in var.apps : app.name => app }

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
    labels    = merge({ app = each.value.name }, each.value.labels)
  }

  spec {
    replicas = each.value.autoscaling.enabled ? null : each.value.replicas

    selector {
      match_labels = {
        app = each.value.name
      }
    }

    template {
      metadata {
        labels = merge({ app = each.value.name }, each.value.labels)
        annotations = merge(
          {
            "eks.amazonaws.com/enable-logging" = each.value.enable_logging ? "true" : "false"
          },
          each.value.enable_logging ? {
            "fluentbit.io/tag" = "logging-enabled.${each.value.name}"
          } : {},
          each.value.pod_annotations
        )
      }

      spec {
        container {
          name  = each.value.name
          image = each.value.image

          port {
            container_port = each.value.port
          }

          dynamic "resources" {
            for_each = each.value.resources != null ? [1] : []
            content {
              limits   = try(each.value.resources.limits, null)
              requests = try(each.value.resources.requests, null)
            }
          }

          dynamic "env" {
            for_each = each.value.env
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "liveness_probe" {
            for_each = each.value.healthcheck.liveness != null ? [each.value.healthcheck.liveness] : []
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
            for_each = each.value.healthcheck.readiness != null ? [each.value.healthcheck.readiness] : []
            content {
              http_get {
                path = readiness_probe.value.http_get.path
                port = readiness_probe.value.http_get.port
              }
              initial_delay_seconds = readiness_probe.value.initial_delay_seconds
              period_seconds        = readiness_probe.value.period_seconds
            }
          }

          dynamic "volume_mount" {
            for_each = each.value.volume_mounts
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
            }
          }
        }

        dynamic "volume" {
          for_each = each.value.volumes
          content {
            name = volume.value.name

            persistent_volume_claim {
              claim_name = volume.value.persistent_volume_claim.claim_name
            }
          }
        }

        dynamic "init_container" {
          for_each = each.value.init_containers
          content {
            name    = init_container.value.name
            image   = init_container.value.image
            command = init_container.value.command
          }
        }

        node_selector = each.value.node_selector

        dynamic "toleration" {
          for_each = each.value.tolerations
          content {
            key      = toleration.value.key
            operator = try(toleration.value.operator, "Equal")
            value    = try(toleration.value.value, null)
            effect   = try(toleration.value.effect, null)
          }
        }

        dynamic "image_pull_secrets" {
          for_each = toset(each.value.image_pull_secrets)
          content {
            name = image_pull_secrets.value
          }
        }

        dynamic "security_context" {
          for_each = each.value.security_context != null ? [1] : []
          content {
            run_as_user  = try(each.value.security_context.run_as_user, null)
            run_as_group = try(each.value.security_context.run_as_group, null)
            fs_group     = try(each.value.security_context.fs_group, null)
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [spec[0].replicas]
  }
}
