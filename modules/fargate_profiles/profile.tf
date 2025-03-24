##############################
# EKS Fargate Profiles (Explicit)
##############################

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "default"
  pod_execution_role_arn = var.eks_fargate_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "default"
  }
}

resource "aws_eks_fargate_profile" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "monitoring"
  pod_execution_role_arn = var.eks_fargate_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "monitoring"
  }
}

resource "aws_eks_fargate_profile" "logging" {
  count = var.enable_logging ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "logging"
  pod_execution_role_arn = var.eks_fargate_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "logging"
  }
}

resource "aws_eks_fargate_profile" "kube_system" {
  count = var.enable_kube_system ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = var.eks_fargate_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "kube-system"
  }
}

##############################
# EKS Fargate Profiles (Dynamic for Add-ons)
##############################

resource "aws_eks_fargate_profile" "addons" {
  for_each = toset(var.profiles_name)

  cluster_name           = var.cluster_name
  fargate_profile_name   = each.value
  pod_execution_role_arn = var.eks_fargate_role_arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = each.value
    }
  }
}
