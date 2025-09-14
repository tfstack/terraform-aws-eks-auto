
# ############################################
# # ECS Cluster Configuration
# ############################################



# data "aws_eks_addon_version" "kube_proxy_latest" {
#   addon_name         = "kube-proxy"
#   kubernetes_version = local.eks_cluster_version
#   most_recent        = true
# }

# data "aws_eks_addon_version" "eks_pod_identity_agent_latest" {
#   addon_name         = "eks-pod-identity-agent"
#   kubernetes_version = local.eks_cluster_version
#   most_recent        = true
# }

# data "aws_eks_addon_version" "metrics_server_latest" {
#   addon_name         = "metrics-server"
#   kubernetes_version = local.eks_cluster_version
#   most_recent        = true
# }


# ##############################
# # IAM Role for EKS Read-Only Access
# ##############################

# resource "aws_eks_access_entry" "readonly_roles" {
#   count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

#   cluster_name  = var.cluster_name
#   principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_view_access.role_names[count.index]}"
# }

# resource "aws_eks_access_policy_association" "view_policy" {
#   count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

#   cluster_name  = var.cluster_name
#   principal_arn = aws_eks_access_entry.readonly_roles[count.index].principal_arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

#   access_scope {
#     type = "cluster"
#   }
# }

# resource "aws_eks_access_policy_association" "readonly_access_policy" {
#   count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

#   cluster_name  = var.cluster_name
#   principal_arn = aws_eks_access_entry.readonly_roles[count.index].principal_arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

#   access_scope {
#     type = "cluster"
#   }
# }

# data "aws_iam_role" "readonly_roles" {
#   count = var.eks_view_access.enabled ? length(var.eks_view_access.role_names) : 0

#   name = var.eks_view_access.role_names[count.index]
# }

# resource "aws_iam_policy" "eks_describe_cluster" {
#   count = var.eks_view_access.enabled ? 1 : 0

#   name = "EKSDescribeCluster"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid      = "DescribeClusterAccess",
#         Effect   = "Allow",
#         Action   = ["eks:DescribeCluster"],
#         Resource = "arn:aws:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
#       },
#       {
#         Sid      = "ListAssociatedAccessPolicies",
#         Effect   = "Allow",
#         Action   = ["eks:ListAssociatedAccessPolicies"],
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_policy_attachment" "readonly_describe_cluster" {
#   count = var.eks_view_access.enabled ? 1 : 0

#   name       = "readonly-describe-cluster"
#   policy_arn = aws_iam_policy.eks_describe_cluster[0].arn
#   roles      = [for role in data.aws_iam_role.readonly_roles : role.name]
# }
