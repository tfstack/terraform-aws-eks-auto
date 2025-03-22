output "eks_cluster_id" {
  value = aws_eks_cluster.this.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "eks_fargate_role_arn" {
  value = aws_iam_role.eks_fargate.arn
}

output "apps_deployed" {
  value = module.apps[0].deployed_apps
}

output "apps_namespace_map" {
  value = module.apps[0].app_namespaces
}
