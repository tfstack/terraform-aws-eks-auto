##############################
# VPC Tags for Private Subnets
##############################

# Default required tag for private subnets
resource "aws_ec2_tag" "private_subnet_default_tag" {
  for_each = { for idx, subnet_id in var.cluster_vpc_config.private_subnet_ids : idx => subnet_id }

  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Custom tags for private subnets
resource "aws_ec2_tag" "private_subnet_custom_tags" {
  count = length(var.cluster_vpc_config.private_subnet_ids) * length(var.private_subnet_custom_tags)

  resource_id = var.cluster_vpc_config.private_subnet_ids[floor(count.index / length(var.private_subnet_custom_tags))]
  key         = element(keys(var.private_subnet_custom_tags), count.index % length(var.private_subnet_custom_tags))
  value       = element(values(var.private_subnet_custom_tags), count.index % length(var.private_subnet_custom_tags))
}

##############################
# EKS Cluster Configuration
##############################

resource "aws_eks_cluster" "this" {
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.eks_auto.arn
  version                   = var.cluster_version
  enabled_cluster_log_types = var.cluster_enabled_log_types

  bootstrap_self_managed_addons = false # REQUIRED when EKS Auto Mode is enabled

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  compute_config {
    enabled       = true
    node_pools    = try([for pool in var.cluster_compute_config.node_pools : pool.name], [])
    node_role_arn = try(var.cluster_compute_config.node_role_arn, null)
  }

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

  dynamic "encryption_config" {
    for_each = var.enable_cluster_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = var.enable_elastic_load_balancing
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  upgrade_policy {
    support_type = try(var.cluster_upgrade_policy.support_type, null)
  }

  zonal_shift_config {
    enabled = try(var.cluster_zonal_shift_config.enabled, false)
  }

  tags = merge(
    { "eks.auto-mode" = "true" },
    var.tags
  )

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}
