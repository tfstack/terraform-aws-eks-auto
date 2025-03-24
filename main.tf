locals {
  eks_addons_map = { for addon in var.eks_addons : addon.name => addon }
}

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
  enable_cloudwatch_logging = anytrue([
    for app in var.apps : try(app.enable_logging, false)
  ])
}

module "logging" {
  source = "./modules/logging"

  cluster_name            = var.cluster_name
  eks_log_prevent_destroy = var.eks_log_prevent_destroy
  eks_log_retention_days  = var.eks_log_retention_days
}

module "eks" {
  source = "./modules/eks"

  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  eks_fargate_role_arn    = module.iam.eks_fargate_role_arn
  eks_auto_nodes_role_arn = module.iam.eks_auto_nodes_role_arn
  cluster_vpc_config      = var.cluster_vpc_config
  # eks_view_access               = var.eks_view_access
  # enable_executor_cluster_admin = var.enable_executor_cluster_admin
  vpc_id = var.vpc_id

  depends_on = [
    module.logging
  ]
}

# module "fargate_profiles" {
#   source = "./modules/fargate_profiles"

#   cluster_name         = module.eks.cluster_name
#   enable_monitoring    = var.fargate_profiles["monitoring"].enabled
#   enable_kube_system   = var.fargate_profiles["kube_system"].enabled
#   enable_logging       = var.fargate_profiles["logging"].enabled
#   profiles_name        = [for addon in var.eks_addons : addon.name]
#   eks_fargate_role_arn = module.iam.eks_fargate_role_arn
#   subnet_ids           = var.cluster_vpc_config.private_subnet_ids
# }

# module "addons" {
#   source = "./modules/addons"

#   cluster_name = module.eks.cluster_name
#   eks_addons   = var.eks_addons

#   depends_on = [
#     module.fargate_profiles
#   ]
# }
