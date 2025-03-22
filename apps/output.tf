output "deployed_apps" {
  description = "List of application names that were deployed"
  value       = [for app in var.apps : app.name]
}

output "app_namespaces" {
  description = "Map of app name to the namespace it was deployed in"
  value = {
    for app in var.apps : app.name => app.namespace != null ? app.namespace : "default"
  }
}
