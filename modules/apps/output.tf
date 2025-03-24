##############################
# Outputs: Deployed Applications
##############################

output "apps_deployed" {
  description = "List of application names that were deployed"
  value       = length(module.apps) > 0 ? module.apps[0].deployed_apps : []
}

output "apps_namespace_map" {
  description = "Map of application name to deployed namespace"
  value       = length(module.apps) > 0 ? module.apps[0].app_namespaces : {}
}
