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
  enable_executor_cluster_admin = var.enable_executor_cluster_admin
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
  vpc_id                  = var.vpc_id

  depends_on = [
    module.logging
  ]
}

module "namespaces" {
  source     = "./modules/namespaces"
  namespaces = distinct([for profile in var.fargate_profiles : profile.namespace])
}

module "fargate_profiles" {
  source = "./modules/fargate_profiles"

  cluster_name         = module.eks.cluster_name
  fargate_profiles     = var.fargate_profiles
  eks_fargate_role_arn = module.iam.eks_fargate_role_arn
  subnet_ids           = var.cluster_vpc_config.private_subnet_ids

  depends_on = [
    module.namespaces
  ]
}

module "executor" {
  source = "./modules/executor"

  cluster_name                  = module.eks.cluster_name
  enable_executor_cluster_admin = var.enable_executor_cluster_admin
}

module "observability" {
  source = "./modules/observability"

  cluster_name                = module.eks.cluster_name
  aws_observability_namespace = "aws-observability"

  depends_on = [
    module.executor
  ]
}

module "metrics" {
  source = "./modules/metrics"

  depends_on = [
    module.eks
  ]
}


# handle delete
# module.eks_auto.module.namespaces.kubernetes_namespace.this["aws-observability"]: Destroying... [id=aws-observability]
# module.eks_auto.module.namespaces.kubernetes_namespace.this["logging"]: Destroying... [id=logging]
# ╷
# │ Error: Unauthorized
# │
# │
# ╵
# ╷
# │ Error: Unauthorized




# # module "addons" {
#   source = "./modules/addons"

#   cluster_name = module.eks.cluster_name
#   eks_addons   = var.eks_addons

#   depends_on = [
#     module.fargate_profiles
#   ]
# }
