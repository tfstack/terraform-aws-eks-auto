locals {
  eks_addons_map = { for addon in var.eks_addons : addon.name => addon }
  enable_metrics_server = anytrue([
    for app in var.apps : try(app.autoscaling.enabled, false)
  ])
}

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
  enable_cloudwatch_logging = anytrue([
    for app in var.apps : try(app.enable_logging, false)
  ])
  enable_executor_cluster_admin  = var.enable_executor_cluster_admin
  enable_metrics_server_irsa     = var.enable_metrics_server_irsa
  oidc_provider_arn              = module.eks.oidc_provider_arn
  oidc_provider_url              = module.eks.oidc_provider_url
  metrics_server_namespace       = var.metrics_server_namespace
  metrics_server_service_account = var.metrics_server_service_account
}

module "logging" {
  source = "./modules/logging"

  cluster_name            = var.cluster_name
  eks_log_prevent_destroy = var.eks_log_prevent_destroy
  eks_log_retention_days  = var.eks_log_retention_days
}

module "eks" {
  source = "./modules/eks"

  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  tags                          = var.tags
  eks_auto_cluster_role_arn     = module.iam.eks_auto_cluster_role_arn
  eks_auto_node_role_arn        = module.iam.eks_auto_node_role_arn
  vpc_id                        = var.vpc_id
  cluster_vpc_config            = var.cluster_vpc_config
  cluster_node_pools            = var.cluster_node_pools
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  enable_cluster_encryption     = var.enable_cluster_encryption
  enable_elastic_load_balancing = var.enable_elastic_load_balancing
  enable_irsa                   = var.enable_irsa

  depends_on = [
    module.logging
  ]
}

# module "executor" {
#   source = "./modules/executor"

#   cluster_name                  = module.eks.cluster_name
#   eks_cluster_endpoint          = module.eks.eks_cluster_endpoint
#   enable_executor_cluster_admin = var.enable_executor_cluster_admin
# }

# module "namespaces" {
#   source = "./modules/namespaces"

#   namespaces = var.namespaces

#   depends_on = [
#     module.executor
#   ]
# }

# # module "observability" {
# #   source = "./modules/observability"

# #   cluster_name                = module.eks.cluster_name
# #   aws_observability_namespace = "aws-observability"

# #   depends_on = [
# #     module.executor
# #   ]
# # }

# # module "metrics" {
# #   source = "./modules/metrics"

# #   depends_on = [
# #     module.eks
# #   ]
# # }

# module "container_insights" {
#   source = "./modules/container_insights"

#   cluster_name              = module.eks.cluster_name
#   enable_container_insights = var.enable_container_insights

#   depends_on = [
#     module.namespaces
#   ]
# }

# module "addons" {
#   source = "./modules/addons"

#   cluster_name    = module.eks.cluster_name
#   cluster_version = module.eks.cluster_version
#   eks_addons      = var.eks_addons

#   depends_on = [
#     module.namespaces
#   ]
# }

# module "helm_releases" {
#   source = "./modules/helm_releases"

#   helm_charts = var.helm_charts

#   depends_on = [
#     module.eks
#   ]
# }
