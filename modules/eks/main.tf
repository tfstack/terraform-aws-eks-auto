locals {
  resolved_cluster_version = (
    var.cluster_version == null || var.cluster_version == "latest"
    ? null
    : var.cluster_version
  )
}
