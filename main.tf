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
  vpc_id                        = var.vpc_id
  cluster_vpc_config            = var.cluster_vpc_config
  cluster_node_pools            = var.cluster_node_pools
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  enable_cluster_encryption     = var.enable_cluster_encryption
  enable_elastic_load_balancing = var.enable_elastic_load_balancing
  enable_oidc                   = var.enable_oidc
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
# Module: EKS Add-ons
#########################################

module "addons" {
  source = "./modules/addons"

  cluster_name                        = module.cluster.cluster_name
  cluster_version                     = module.cluster.cluster_version
  eks_addons                          = var.eks_addons
  oidc_provider_arn                   = module.cluster.oidc_provider_arn
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  tags                                = var.tags

  depends_on = [
    module.namespaces
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
    module.addons # Wait for OIDC provider to be ready
  ]
}

#########################################
# Module: Container Insights (Fluent Bit)
#########################################

module "container_insights" {
  source = "./modules/container_insights"

  cluster_name              = module.cluster.cluster_name
  enable_container_insights = var.enable_container_insights
  fluentbit_namespace       = var.fluentbit_namespace
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
# Module: Workloads
#########################################

module "workloads" {
  for_each = { for workload in var.workloads : workload.name => workload }
  source   = "./modules/workload"

  name         = each.value.name
  namespace    = each.value.namespace
  cluster_name = module.cluster.cluster_name
  replicas     = each.value.replicas
  labels       = each.value.labels

  create_namespace   = each.value.create_namespace
  namespace_metadata = each.value.namespace_metadata

  service_account_name = each.value.service_account_name

  irsa = {
    enabled           = each.value.irsa.enabled
    oidc_provider_arn = each.value.irsa.enabled ? module.cluster.oidc_provider_arn : ""
    policy_arns       = each.value.irsa.policy_arns
  }

  containers      = each.value.containers
  init_containers = each.value.init_containers
  volumes         = each.value.volumes
  configmaps      = each.value.configmaps

  create_service      = each.value.create_service
  service_type        = each.value.service_type
  service_ports       = each.value.service_ports
  service_annotations = each.value.service_annotations

  create_ingress      = each.value.create_ingress
  ingress_scheme      = each.value.ingress_scheme
  ingress_protocol    = each.value.ingress_protocol
  ingress_annotations = each.value.ingress_annotations
  ingress_rules       = each.value.ingress_rules

  logging = each.value.logging
  tags    = merge(var.tags, each.value.tags)

  depends_on = [
    module.container_insights
  ]
}
