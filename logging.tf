module "logging" {
  source                 = "./logging"
  cluster_name           = var.cluster_name
  eks_log_retention_days = var.eks_log_retention_days
}
