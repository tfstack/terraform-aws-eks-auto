resource "kubernetes_namespace" "this" {
  for_each = {
    for ns in var.namespaces : ns => ns
    if !contains(["default", "kube-system", "kube-public", "kube-node-lease"], ns)
  }

  metadata {
    name = each.value
  }
}
