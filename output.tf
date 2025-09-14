output "workloads" {
  description = "Workload module outputs"
  value       = module.workloads
}

output "alb_dns_names" {
  description = "DNS names of all Application Load Balancers"
  value = {
    for k, v in module.workloads : k => v.alb_dns_name
  }
}

output "alb_urls" {
  description = "URLs of all Application Load Balancers"
  value = {
    for k, v in module.workloads : k => v.alb_url
  }
}

# output "cluster_version" {
#   description = "The Kubernetes version used by the EKS cluster, if exported by the module."
#   value       = try(module.cluster.cluster_version, "unknown")
# }
