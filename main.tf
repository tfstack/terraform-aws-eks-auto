#########################################
# Locals
#########################################

locals {
  eks_addons_map = { for addon in var.eks_addons : addon.name => addon }

  enable_metrics_server = anytrue([
    for app in var.apps : try(app.autoscaling.enabled, false)
  ])
}

#########################################
# Module: EKS Cluster
#########################################

module "cluster" {
  source = "./modules/cluster"

  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  tags                          = var.tags
  eks_auto_cluster_role_arn     = module.cluster.eks_auto_cluster_role_arn
  eks_auto_node_role_arn        = module.cluster.eks_auto_node_role_arn
  vpc_id                        = var.vpc_id
  cluster_vpc_config            = var.cluster_vpc_config
  cluster_node_pools            = var.cluster_node_pools
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  enable_cluster_encryption     = var.enable_cluster_encryption
  enable_elastic_load_balancing = var.enable_elastic_load_balancing
  enable_irsa                   = var.enable_irsa
  eks_log_prevent_destroy       = var.eks_log_prevent_destroy
  eks_log_retention_days        = var.eks_log_retention_days
}

#########################################
# Module: Kubernetes Namespaces
#########################################

module "namespaces" {
  source = "./modules/namespaces"

  namespaces = var.namespaces

  depends_on = [
    module.cluster
  ]
}

#########################################
# Module: EBS CSI Controller
#########################################

module "ebs_csi_controller" {
  source = "./modules/ebs_csi_controller"

  cluster_name                 = module.cluster.cluster_name
  enable_ebs_csi_controller    = var.enable_ebs_csi_controller
  ebs_csi_controller_sa_name   = var.ebs_csi_controller_sa_name
  ebs_csi_driver_chart_version = var.ebs_csi_driver_chart_version
  oidc_provider_arn            = module.cluster.oidc_provider_arn
  oidc_provider_url            = module.cluster.oidc_provider_url

  tags = var.tags

  depends_on = [
    module.namespaces
  ]
}

#########################################
# Module: Container Insights (Fluent Bit)
#########################################

module "container_insights" {
  source = "./modules/container_insights"

  cluster_name              = module.cluster.cluster_name
  enable_container_insights = var.enable_container_insights
  fluentbit_sa_namespace    = var.fluentbit_sa_namespace
  fluentbit_sa_name         = var.fluentbit_sa_name
  oidc_provider_arn         = module.cluster.oidc_provider_arn
  oidc_provider_url         = module.cluster.oidc_provider_url
  eks_log_prevent_destroy   = var.eks_log_prevent_destroy
  eks_log_retention_days    = var.eks_log_retention_days

  depends_on = [
    module.ebs_csi_controller
  ]
}

#########################################
# Module: EKS Add-ons - Prometheus
#########################################

module "prometheus" {
  source = "./modules/prometheus"

  enable_prometheus        = var.enable_prometheus
  prometheus_chart_version = var.prometheus_chart_version

  depends_on = [
    module.namespaces
  ]
}

#########################################
# Module: EKS Add-ons
#########################################

module "addons" {
  source = "./modules/addons"

  cluster_name    = module.cluster.cluster_name
  cluster_version = module.cluster.cluster_version
  eks_addons      = var.eks_addons

  depends_on = [
    module.namespaces
  ]
}

#########################################
# Module: Kubernetes Applications
#########################################

module "k8s_apps" {
  source = "./modules/k8s_apps"

  apps = var.apps

  depends_on = [
    module.namespaces,
    module.container_insights
  ]
}

# # module "observability" {
# #   source = "./modules/observability"

# #   cluster_name                = module.cluster.cluster_name
# #   aws_observability_namespace = "aws-observability"

# #   depends_on = [
# #     module.executor
# #   ]
# # }

# # module "metrics" {
# #   source = "./modules/metrics"

# #   depends_on = [
# #     module.cluster
# #   ]
# # }

# module "helm_releases" {
#   source = "./modules/helm_releases"

#   helm_charts = var.helm_charts

#   depends_on = [
#     module.cluster
#   ]
# }
