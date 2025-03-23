
##############################
# IAM Role for EKS Auto Mode Nodes
##############################

resource "aws_iam_role" "eks_auto_nodes" {
  name = "${var.cluster_name}-eks-auto-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eks_auto_nodes" {
  name = "${var.cluster_name}-eks-auto-nodes"
  role = aws_iam_role.eks_auto_nodes.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowMinimalWorkerNodeAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowContainerRegistryPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

##############################
# IAM Role for EKS Read-Only Access
##############################

resource "aws_eks_access_entry" "readonly_roles" {
  count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_view_access.role_names[count.index]}"
}

resource "aws_eks_access_policy_association" "view_policy" {
  count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.readonly_roles[count.index].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "readonly_access_policy" {
  count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.readonly_roles[count.index].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }
}

data "aws_iam_role" "readonly_roles" {
  count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

  name = var.eks_view_access.role_names[count.index]
}

resource "aws_iam_policy" "eks_describe_cluster" {
  count = var.eks_view_access.enabled ? 1 : 0

  name = "EKSDescribeCluster"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "DescribeClusterAccess",
        Effect   = "Allow",
        Action   = ["eks:DescribeCluster"],
        Resource = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      },
      {
        Sid      = "ListAssociatedAccessPolicies",
        Effect   = "Allow",
        Action   = ["eks:ListAssociatedAccessPolicies"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "readonly_describe_cluster" {
  count = var.eks_view_access.enabled ? 1 : 0

  name       = "readonly-describe-cluster"
  policy_arn = aws_iam_policy.eks_describe_cluster[0].arn
  roles      = [for role in data.aws_iam_role.readonly_roles : role.name]
}

data "aws_iam_role" "terraform_executor" {
  name = split("/", data.aws_caller_identity.current.arn)[1]
}

locals {
  executor_role_name = split("/", data.aws_caller_identity.current.arn)[1]
}

resource "aws_eks_access_entry" "terraform_executor" {
  count = var.enable_executor_cluster_admin ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.executor_role_name}"

  depends_on = [
    aws_eks_cluster.this
  ]
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
