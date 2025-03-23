module "apps" {
  source = "./apps"
  count  = length(var.apps) > 0 ? 1 : 0

  apps             = var.apps
  cluster_name     = aws_eks_cluster.this.name
  cluster_endpoint = aws_eks_cluster.this.endpoint
  cluster_ca       = aws_eks_cluster.this.certificate_authority[0].data

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    aws_eks_access_policy_association.terraform_executor,
    aws_eks_addon.this,
    aws_eks_fargate_profile.default,
    aws_eks_fargate_profile.monitoring,
    aws_eks_fargate_profile.logging,
    aws_eks_fargate_profile.addons,
    module.logging
  ]
}
