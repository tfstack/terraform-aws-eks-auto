#########################################
# Output: App Deployments Metadata
#########################################

output "app_deployments" {
  description = "Map of deployment names to namespaces"
  value = {
    for name, dep in kubernetes_deployment.this :
    name => {
      name      = dep.metadata[0].name
      namespace = dep.metadata[0].namespace
    }
  }
}
