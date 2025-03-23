resource "helm_release" "metrics_server" {
  count = local.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server.version

  create_namespace = false

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
  }

  set {
    name  = "resources.limits.cpu"
    value = var.metrics_server.resources.cpu
  }

  set {
    name  = "resources.limits.memory"
    value = var.metrics_server.resources.memory
  }

  depends_on = [
    aws_eks_cluster.this
  ]
}
