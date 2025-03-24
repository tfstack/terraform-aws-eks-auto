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
