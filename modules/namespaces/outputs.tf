#########################################
# Namespace Module Outputs
#########################################

output "namespace_names" {
  description = "List of created namespace names"
  value       = [for ns in kubernetes_namespace.this : ns.metadata[0].name]
}

output "namespace_details" {
  description = "Map of namespace details"
  value = {
    for k, v in kubernetes_namespace.this : k => {
      name        = v.metadata[0].name
      uid         = v.metadata[0].uid
      labels      = v.metadata[0].labels
      annotations = v.metadata[0].annotations
    }
  }
}
