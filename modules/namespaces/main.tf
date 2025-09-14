#########################################
# Namespace Module Main Configuration
#########################################

# This module creates Kubernetes namespaces with optional labels and annotations
# It automatically excludes system namespaces to prevent conflicts

resource "kubernetes_namespace" "this" {
  for_each = {
    for ns in var.namespaces : ns => ns
    if !contains(["default", "kube-system", "kube-public", "kube-node-lease"], ns)
  }

  metadata {
    name        = each.value
    labels      = var.namespace_labels
    annotations = var.namespace_annotations
  }
}
