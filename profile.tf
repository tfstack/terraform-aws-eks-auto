##############################
# EKS Fargate Profiles (Explicit)
##############################

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = var.cluster_vpc_config.private_subnet_ids

  selector {
    namespace = "default"
  }
}

resource "aws_eks_fargate_profile" "monitoring" {
  count = var.fargate_profiles.monitoring.enabled ? 1 : 0

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "monitoring"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = var.cluster_vpc_config.private_subnet_ids

  selector {
    namespace = "monitoring"
  }
}

resource "aws_eks_fargate_profile" "logging" {
  count = var.fargate_profiles.logging.enabled ? 1 : 0

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "logging"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = var.cluster_vpc_config.private_subnet_ids

  selector {
    namespace = "logging"
  }
}

resource "aws_eks_fargate_profile" "kube_system" {
  # count = var.fargate_profiles.kube_system.enabled ? 1 : 0

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = var.cluster_vpc_config.private_subnet_ids

  selector {
    namespace = "kube-system"
  }
}

##############################
# EKS Fargate Profiles (Dynamic for Add-ons)
##############################

resource "aws_eks_fargate_profile" "addons" {
  for_each = { for addon in var.eks_addons : addon.name => addon if addon.fargate_required }

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.value.name
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = var.cluster_vpc_config.private_subnet_ids

  selector {
    namespace = each.value.namespace
    labels    = { "k8s-app" = coalesce(each.value.label_override, each.value.name) }
  }
}
