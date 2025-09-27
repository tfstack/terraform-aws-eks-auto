resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = local.resolved_cluster_version
  role_arn = var.eks_auto_cluster_role_arn != null ? var.eks_auto_cluster_role_arn : aws_iam_role.eks_auto_cluster.arn

  #######################################
  # Logging and Monitoring
  #######################################
  enabled_cluster_log_types = var.cluster_enabled_log_types

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster_with_prevent_destroy,
    aws_cloudwatch_log_group.eks_cluster_without_prevent_destroy,
    aws_cloudwatch_log_group.eks_logs_with_prevent_destroy,
    aws_cloudwatch_log_group.eks_logs_without_prevent_destroy
  ]

  #######################################
  # Access Control
  #######################################
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  #######################################
  # Networking
  #######################################
  vpc_config {
    security_group_ids = compact(distinct(concat(
      var.cluster_vpc_config.security_group_ids,
      var.create_security_group ? [aws_security_group.eks[0].id] : []
    )))
    subnet_ids              = var.cluster_vpc_config.private_subnet_ids
    endpoint_private_access = var.cluster_vpc_config.endpoint_private_access
    endpoint_public_access  = var.cluster_vpc_config.endpoint_public_access
    public_access_cidrs     = var.cluster_vpc_config.public_access_cidrs
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = var.cluster_vpc_config.service_cidr
    elastic_load_balancing {
      enabled = var.enable_elastic_load_balancing
    }
  }

  #######################################
  # Compute
  #######################################
  compute_config {
    enabled       = true
    node_pools    = var.cluster_node_pools
    node_role_arn = var.eks_auto_node_role_arn != null ? var.eks_auto_node_role_arn : aws_iam_role.eks_auto_node.arn
  }

  #######################################
  # Encryption
  #######################################
  dynamic "encryption_config" {
    for_each = var.enable_cluster_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  #######################################
  # Storage
  #######################################
  storage_config {
    block_storage {
      enabled = true
    }
  }

  #######################################
  # Upgrade & Zonal Shift
  #######################################
  upgrade_policy {
    support_type = try(var.cluster_upgrade_policy.support_type, null)
  }

  zonal_shift_config {
    enabled = try(var.cluster_zonal_shift_config.enabled, false)
  }

  #######################################
  # Meta & Tags
  #######################################
  bootstrap_self_managed_addons = false # REQUIRED when EKS Auto Mode is enabled

  tags = merge(
    {
      "eks.auto-mode"                               = "true"
      "Name"                                        = "${var.cluster_name}-eks-auto-cluster"
      "alpha.eksctl.io/cluster-name"                = var.cluster_name
      "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.cluster_name
    },
    var.tags
  )

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}

#######################################
# Auth for cluster access
#######################################
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}
