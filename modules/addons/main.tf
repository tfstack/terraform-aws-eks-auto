data "aws_eks_addon_version" "latest_version" {
  for_each = {
    for addon in var.eks_addons :
    addon.name => addon
    if addon.version == "latest"
  }

  addon_name         = each.value.name
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "this" {
  for_each = { for addon in var.eks_addons : addon.name => addon }

  cluster_name = var.cluster_name
  addon_name   = each.value.name

  addon_version = (
    each.value.version == "latest"
    ? data.aws_eks_addon_version.latest_version[each.key].version
    : each.value.version
  )

  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  tags                        = each.value.tags
  preserve                    = each.value.preserve
}
