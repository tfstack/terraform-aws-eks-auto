##############################
# EKS Fargate Profiles
##############################

resource "aws_eks_fargate_profile" "this" {
  for_each = {
    for profile in var.fargate_profiles : profile.name => profile
  }

  cluster_name           = var.cluster_name
  fargate_profile_name   = each.value.name
  pod_execution_role_arn = var.eks_fargate_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = each.value.namespace
    labels    = each.value.labels
  }
}
