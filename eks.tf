# Add EKS-required subnet tags
# Always apply the required EKS tag for private subnets
resource "aws_ec2_tag" "private_subnet_default_tag" {
  count = length(var.vpc.private_subnets)

  resource_id = var.vpc.private_subnets[count.index].id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Apply user-defined custom tags to private subnets
resource "aws_ec2_tag" "private_subnet_custom_tags" {
  for_each = var.private_subnet_custom_tags

  resource_id = var.vpc.private_subnets[0].id
  key         = each.key
  value       = each.value
}


resource "aws_eks_cluster" "this" {
  name                      = var.cluster_name
  role_arn                  = var.use_existing_role ? var.existing_role_arn : aws_iam_role.eks_auto.arn
  version                   = var.cluster_version
  enabled_cluster_log_types = var.cluster_enabled_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  compute_config {
    enabled       = true
    node_pools    = try(var.cluster_compute_config.node_pools, [])
    node_role_arn = try(var.cluster_compute_config.node_role_arn, null)
  }

  vpc_config {
    security_group_ids      = var.cluster_vpc_config.security_group_ids
    subnet_ids              = var.cluster_vpc_config.subnet_ids
    endpoint_private_access = var.cluster_vpc_config.endpoint_private_access
    endpoint_public_access  = var.cluster_vpc_config.endpoint_public_access
    public_access_cidrs     = var.cluster_vpc_config.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = var.cluster_encryption_config.key_arn
    }
    resources = var.cluster_encryption_config.resources
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
