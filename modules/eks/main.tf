# ############################################
# # ECS Cluster Configuration
# ############################################

# data "aws_eks_addon_version" "vpc_cni_latest" {
#   addon_name         = "vpc-cni"
#   kubernetes_version = local.eks_cluster_version
#   most_recent        = true
# }

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
