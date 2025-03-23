module "eks" {
  source = "./modules/eks"
}

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}
