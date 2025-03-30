resource "helm_release" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = local.prometheus_version
  namespace  = "prometheus"

  create_namespace = false

  set {
    name  = "server.persistentVolume.storageClass"
    value = "gp2"
  }

  set {
    name  = "alertmanager.persistentVolume.storageClass"
    value = "gp2"
  }

  set {
    name  = "alertmanager.persistentVolume.storageClass"
    value = "gp2"
  }
}
