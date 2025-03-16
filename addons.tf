resource "aws_eks_addon" "this" {
  for_each = { for addon in var.eks_addons : addon.name => addon }

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value.name
  addon_version               = each.value.addon_version
  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  tags                        = each.value.tags
  preserve                    = each.value.preserve

  depends_on = [
    aws_eks_cluster.this
  ]
}
