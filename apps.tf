module "apps" {
  source = "./apps"
  count  = length(var.apps) > 0 ? 1 : 0

  apps             = var.apps
  cluster_name     = aws_eks_cluster.this.name
  cluster_endpoint = aws_eks_cluster.this.endpoint
  cluster_ca       = aws_eks_cluster.this.certificate_authority[0].data

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    aws_eks_access_policy_association.terraform_executor,
    aws_eks_addon.this,
    aws_eks_fargate_profile.addons,
    aws_eks_fargate_profile.default,
    aws_eks_fargate_profile.kube_system,
    aws_eks_fargate_profile.logging,
    aws_eks_fargate_profile.monitoring,
    module.logging
  ]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0" # Latest stable

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls,--kubelet-preferred-address-types=Hostname}"
  }
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "200Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "300Mi"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_fargate_profile.kube_system
  ]
}
