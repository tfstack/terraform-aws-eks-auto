#########################################
# Workload Module
#########################################

locals {
  target_namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata[0].name : var.namespace

  common_labels = merge(
    var.labels,
    {
      "app.kubernetes.io/name"     = var.name
      "app.kubernetes.io/instance" = var.name
    }
  )
}

#########################################
# Namespace (Optional)
#########################################

resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name        = var.namespace
    labels      = merge(local.common_labels, var.namespace_metadata.labels)
    annotations = var.namespace_metadata.annotations
  }
}

#########################################
# Service Account with IRSA
#########################################

resource "aws_iam_role" "irsa" {
  count = var.irsa.enabled ? 1 : 0

  name = "${var.cluster_name}-${var.name}-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.irsa.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.irsa.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:${local.target_namespace}:${var.service_account_name}"
            "${replace(var.irsa.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "irsa" {
  count = var.irsa.enabled ? length(var.irsa.policy_arns) : 0

  role       = aws_iam_role.irsa[0].name
  policy_arn = var.irsa.policy_arns[count.index]
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = var.service_account_name != null ? var.service_account_name : var.name
    namespace = local.target_namespace
    labels    = local.common_labels
    annotations = var.irsa.enabled ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa[0].arn
    } : {}
  }

  depends_on = [kubernetes_namespace.this]
}

#########################################
# ConfigMaps
#########################################

resource "kubernetes_config_map" "this" {
  for_each = { for cm in var.configmaps : cm.name => cm }

  metadata {
    name      = each.value.name
    namespace = local.target_namespace
    labels    = local.common_labels
  }

  data        = each.value.data
  binary_data = each.value.binary_data

  depends_on = [kubernetes_namespace.this]
}

#########################################
# Deployment
#########################################

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.name
    namespace = local.target_namespace
    labels    = local.common_labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = var.name
        "app.kubernetes.io/instance" = var.name
      }
    }

    template {
      metadata {
        labels = local.common_labels
      }

      spec {
        service_account_name = kubernetes_service_account.this.metadata[0].name

        dynamic "init_container" {
          for_each = var.init_containers
          content {
            name    = init_container.value.name
            image   = init_container.value.image
            command = init_container.value.command
            args    = init_container.value.args

            dynamic "env" {
              for_each = init_container.value.env
              content {
                name  = env.value.name
                value = env.value.value
              }
            }

            dynamic "resources" {
              for_each = init_container.value.resources != null ? [init_container.value.resources] : []
              content {
                limits   = resources.value.limits
                requests = resources.value.requests
              }
            }
          }
        }

        dynamic "container" {
          for_each = var.containers
          content {
            name    = container.value.name
            image   = container.value.image
            command = container.value.command
            args    = container.value.args

            dynamic "env" {
              for_each = container.value.env
              content {
                name  = env.value.name
                value = env.value.value
              }
            }

            dynamic "resources" {
              for_each = container.value.resources != null ? [container.value.resources] : []
              content {
                limits   = resources.value.limits
                requests = resources.value.requests
              }
            }

            dynamic "volume_mount" {
              for_each = container.value.volume_mounts
              content {
                name       = volume_mount.value.name
                mount_path = volume_mount.value.mount_path
              }
            }
          }
        }

        dynamic "volume" {
          for_each = var.volumes
          content {
            name = volume.value.name

            dynamic "config_map" {
              for_each = volume.value.config_map != null ? [volume.value.config_map] : []
              content {
                name = config_map.value.name
              }
            }

            dynamic "secret" {
              for_each = volume.value.secret != null ? [volume.value.secret] : []
              content {
                secret_name = secret.value.secret_name
              }
            }

            dynamic "empty_dir" {
              for_each = volume.value.empty_dir != null ? [volume.value.empty_dir] : []
              content {
                size_limit = empty_dir.value.size_limit
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_account.this,
    kubernetes_config_map.this
  ]
}

#########################################
# Service
#########################################

resource "kubernetes_service" "this" {
  count = var.create_service ? 1 : 0

  metadata {
    name        = var.name
    namespace   = local.target_namespace
    labels      = local.common_labels
    annotations = var.service_annotations
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = var.name
      "app.kubernetes.io/instance" = var.name
    }

    dynamic "port" {
      for_each = var.service_ports
      content {
        name        = port.value.name
        port        = port.value.port
        target_port = port.value.target_port
        protocol    = port.value.protocol
      }
    }

    type = var.service_type
  }

  depends_on = [kubernetes_deployment.this]
}

resource "kubernetes_ingress_v1" "this" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = var.name
    namespace = local.target_namespace
    labels    = local.common_labels
    annotations = merge(
      var.ingress_annotations,
      {
        "kubernetes.io/ingress.class"                                   = "alb"
        "alb.ingress.kubernetes.io/scheme"                              = var.ingress_scheme
        "alb.ingress.kubernetes.io/group.name"                          = var.name
        "alb.ingress.kubernetes.io/manage-backend-security-group-rules" = "false"
      }
    )
  }

  spec {
    dynamic "rule" {
      for_each = var.ingress_rules
      content {
        host = rule.value.host != "" ? rule.value.host : null

        http {
          dynamic "path" {
            for_each = rule.value.http_paths
            content {
              path      = path.value.path
              path_type = path.value.path_type

              backend {
                service {
                  name = kubernetes_service.this[0].metadata[0].name
                  port {
                    number = path.value.backend_port
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # NOTE: do NOT use create_before_destroy here; it can deadlock with ALB/IngressGroup
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["alb.ingress.kubernetes.io/load-balancer-name"],
      metadata[0].annotations["alb.ingress.kubernetes.io/target-group-arn"]
    ]
  }

  timeouts {
    create = "5m"
    delete = "10m" # Increased timeout for cleanup issues
  }

  depends_on = [kubernetes_service.this]
}
