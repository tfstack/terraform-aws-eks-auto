module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  # eks_view_access               = var.eks_view_access
  # enable_executor_cluster_admin = var.enable_executor_cluster_admin
}


module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
  enable_cloudwatch_logging = anytrue([
    for app in var.apps : try(app.enable_logging, false)
  ])
}
