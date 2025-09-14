data "aws_eks_cluster_versions" "available" {}

data "aws_eks_addon_version" "latest_version" {
  for_each = {
    for addon in var.eks_addons :
    addon.name => addon
    if addon.version == "latest" || addon.version == null
  }

  addon_name         = each.value.name
  kubernetes_version = local.k8s_version
  most_recent        = true
}

locals {
  latest_k8s_version = reverse(sort([
    for v in data.aws_eks_cluster_versions.available.cluster_versions : v.cluster_version
  ]))[0]

  k8s_version = var.cluster_version == "latest" ? local.latest_k8s_version : var.cluster_version
}

resource "aws_eks_addon" "this" {
  for_each = { for addon in var.eks_addons : addon.name => addon }

  cluster_name = var.cluster_name
  addon_name   = each.value.name

  addon_version = (
    contains(["latest", null], each.value.version)
    ? data.aws_eks_addon_version.latest_version[each.key].version
    : each.value.version
  )

  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  tags                        = each.value.tags
  preserve                    = each.value.preserve
}

#########################################
# AWS Load Balancer Controller Helm Chart
#########################################

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.0"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.aws_load_balancer_controller[0].metadata[0].name
    },
    {
      name  = "region"
      value = data.aws_region.current.region
    },
    {
      name  = "vpcId"
      value = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
    }
  ]

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller,
    kubernetes_cluster_role.aws_load_balancer_controller,
    kubernetes_cluster_role_binding.aws_load_balancer_controller
  ]
}

data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}
