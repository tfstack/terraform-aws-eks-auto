data "aws_caller_identity" "current" {}

locals {
  executor_role_name = split("/", data.aws_caller_identity.current.arn)[1]
}

data "aws_iam_role" "terraform_executor" {
  name = split("/", data.aws_caller_identity.current.arn)[1]
}

resource "aws_eks_access_entry" "terraform_executor" {
  count = var.enable_executor_cluster_admin ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.executor_role_name}"
}

resource "aws_eks_access_policy_association" "terraform_executor" {
  count = var.enable_executor_cluster_admin ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.terraform_executor[0].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# resource "kubernetes_config_map" "aws_auth_executor" {
#   count = var.patch_aws_auth ? 1 : 0

#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.executor_role_name}"
#         username = "terraform"
#         groups   = ["system:masters"]
#       }
#     ])
#   }

#   lifecycle {
#     ignore_changes = [data] # Avoid drift if other tools modify it
#   }

#   depends_on = [aws_eks_access_entry.terraform_executor]
# }
# variable "patch_aws_auth" {
#   description = "Whether to also patch aws-auth for compatibility with the Kubernetes provider"
#   type        = bool
#   default     = true
# }
