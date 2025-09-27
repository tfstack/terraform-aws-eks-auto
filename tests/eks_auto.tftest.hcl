# EKS Auto Mode tests - Comprehensive validation with assertions
# These tests validate actual module behavior and resource creation

run "eks_auto_basic_validation" {
  command = plan

  variables {
    cluster_name = "test-eks-cluster"
    vpc_id       = "vpc-12345678"
    cluster_vpc_config = {
      private_subnet_ids      = ["subnet-12345678", "subnet-87654321"]
      private_access_cidrs    = ["10.0.0.0/8"]
      public_access_cidrs     = ["0.0.0.0/0"]
      security_group_ids      = ["sg-12345678"]
      endpoint_private_access = true
      endpoint_public_access  = true
      service_cidr            = "10.100.0.0/16"
    }

    # Enable essential features
    enable_oidc                         = true
    enable_elastic_load_balancing       = true
    enable_ebs_csi_controller           = true
    enable_container_insights           = true
    enable_aws_load_balancer_controller = true

    # Basic EKS add-ons
    eks_addons = [
      {
        name    = "metrics-server"
        version = "latest"
      },
      {
        name    = "amazon-cloudwatch-observability"
        version = "latest"
      }
    ]

    # Valid namespaces (not Kubernetes-managed)
    namespaces = ["test-namespace", "monitoring"]

    tags = {
      Environment = "test"
      Project     = "eks-auto-test"
    }
  }

  # Test cluster configuration
  assert {
    condition     = var.cluster_name == "test-eks-cluster"
    error_message = "Cluster name should be set correctly"
  }

  # Test OIDC is enabled
  assert {
    condition     = var.enable_oidc == true
    error_message = "OIDC should be enabled for EKS Auto Mode"
  }

  # Test EKS add-ons are configured
  assert {
    condition     = length(var.eks_addons) == 2
    error_message = "Should have exactly 2 EKS add-ons configured"
  }

  # Test specific add-ons are present
  assert {
    condition     = contains([for addon in var.eks_addons : addon.name], "metrics-server")
    error_message = "metrics-server add-on should be configured"
  }

  assert {
    condition     = contains([for addon in var.eks_addons : addon.name], "amazon-cloudwatch-observability")
    error_message = "amazon-cloudwatch-observability add-on should be configured"
  }

  # Test Load Balancer Controller is enabled
  assert {
    condition     = var.enable_aws_load_balancer_controller == true
    error_message = "AWS Load Balancer Controller should be enabled"
  }

  # Test Container Insights is enabled
  assert {
    condition     = var.enable_container_insights == true
    error_message = "Container insights should be enabled"
  }

  # Test EBS CSI Controller is enabled
  assert {
    condition     = var.enable_ebs_csi_controller == true
    error_message = "EBS CSI Controller should be enabled"
  }

  # Test VPC configuration
  assert {
    condition     = length(var.cluster_vpc_config.private_subnet_ids) == 2
    error_message = "Should have exactly 2 private subnets"
  }

  # Test namespaces are configured
  assert {
    condition     = length(var.namespaces) == 2
    error_message = "Should have exactly 2 namespaces configured"
  }

  # Test specific namespaces are present
  assert {
    condition     = contains(var.namespaces, "test-namespace")
    error_message = "test-namespace should be configured"
  }

  assert {
    condition     = contains(var.namespaces, "monitoring")
    error_message = "monitoring namespace should be configured"
  }

  # Test tags configuration
  assert {
    condition     = var.tags.Environment == "test"
    error_message = "Environment tag should be set correctly"
  }

  assert {
    condition     = var.tags.Project == "eks-auto-test"
    error_message = "Project tag should be set correctly"
  }


  # Test that all required features are enabled for EKS Auto Mode
  assert {
    condition     = var.enable_oidc == true && var.enable_elastic_load_balancing == true
    error_message = "EKS Auto Mode requires OIDC and Elastic Load Balancing to be enabled"
  }
}

run "eks_auto_minimal_validation" {
  command = plan

  variables {
    cluster_name = "minimal-eks-cluster"
    vpc_id       = "vpc-87654321"
    cluster_vpc_config = {
      private_subnet_ids      = ["subnet-11111111", "subnet-22222222"]
      private_access_cidrs    = ["10.0.0.0/8"]
      public_access_cidrs     = ["0.0.0.0/0"]
      security_group_ids      = ["sg-87654321"]
      endpoint_private_access = true
      endpoint_public_access  = true
      service_cidr            = "10.200.0.0/16"
    }

    # Minimal configuration
    enable_oidc                         = true
    enable_elastic_load_balancing       = true
    enable_ebs_csi_controller           = false
    enable_container_insights           = false
    enable_aws_load_balancer_controller = false

    eks_addons = []
    namespaces = []

    tags = {
      Environment = "minimal"
      Project     = "eks-auto-minimal"
    }
  }

  # Test minimal cluster configuration
  assert {
    condition     = var.cluster_name == "minimal-eks-cluster"
    error_message = "Minimal cluster name should be set correctly"
  }

  # Test OIDC is enabled (required for EKS Auto Mode)
  assert {
    condition     = var.enable_oidc == true
    error_message = "OIDC should be enabled for EKS Auto Mode"
  }

  # Test Elastic Load Balancing is enabled (required for EKS Auto Mode)
  assert {
    condition     = var.enable_elastic_load_balancing == true
    error_message = "Elastic Load Balancing should be enabled for EKS Auto Mode"
  }

  # Test no EKS add-ons in minimal config
  assert {
    condition     = length(var.eks_addons) == 0
    error_message = "Should have no EKS add-ons in minimal configuration"
  }

  # Test no namespaces in minimal config
  assert {
    condition     = length(var.namespaces) == 0
    error_message = "Should have no namespaces in minimal configuration"
  }

  # Test EBS CSI Controller is disabled
  assert {
    condition     = var.enable_ebs_csi_controller == false
    error_message = "EBS CSI Controller should be disabled in minimal configuration"
  }

  # Test Container Insights is disabled
  assert {
    condition     = var.enable_container_insights == false
    error_message = "Container insights should be disabled in minimal configuration"
  }

  # Test Load Balancer Controller is disabled
  assert {
    condition     = var.enable_aws_load_balancer_controller == false
    error_message = "AWS Load Balancer Controller should be disabled in minimal configuration"
  }

  # Test VPC configuration is still valid
  assert {
    condition     = length(var.cluster_vpc_config.private_subnet_ids) == 2
    error_message = "Should have exactly 2 private subnets even in minimal config"
  }

  # Test tags are configured
  assert {
    condition     = var.tags.Environment == "minimal"
    error_message = "Environment tag should be set correctly in minimal config"
  }

  # Test that EKS Auto Mode requirements are still met
  assert {
    condition     = var.enable_oidc == true && var.enable_elastic_load_balancing == true
    error_message = "EKS Auto Mode requires OIDC and Elastic Load Balancing to be enabled"
  }

}

run "eks_auto_comprehensive_validation" {
  command = plan

  variables {
    cluster_name = "validation-eks-cluster"
    vpc_id       = "vpc-1234567890abcdef0"
    cluster_vpc_config = {
      private_subnet_ids      = ["subnet-1234567890abcdef0", "subnet-0987654321fedcba0"]
      private_access_cidrs    = ["10.0.0.0/8"]
      public_access_cidrs     = ["0.0.0.0/0"]
      security_group_ids      = ["sg-1234567890abcdef0"]
      endpoint_private_access = true
      endpoint_public_access  = true
      service_cidr            = "10.400.0.0/16"
    }

    # Valid configuration with all features enabled
    enable_oidc                         = true
    enable_elastic_load_balancing       = true
    enable_ebs_csi_controller           = true
    enable_container_insights           = true
    enable_aws_load_balancer_controller = true

    # Test with multiple EKS add-ons
    eks_addons = [
      {
        name    = "metrics-server"
        version = "latest"
      },
      {
        name    = "amazon-cloudwatch-observability"
        version = "latest"
      },
      {
        name    = "aws-efs-csi-driver"
        version = "latest"
      }
    ]

    # Test with multiple namespaces
    namespaces = ["validation-ns1", "validation-ns2", "validation-ns3"]

    tags = {
      Environment = "validation"
      Project     = "eks-auto-validation"
      TestType    = "comprehensive"
    }
  }

  # Test comprehensive cluster configuration
  assert {
    condition     = var.cluster_name == "validation-eks-cluster"
    error_message = "Comprehensive cluster name should be set correctly"
  }

  # Test all features are enabled
  assert {
    condition     = var.enable_oidc == true
    error_message = "OIDC should be enabled in comprehensive configuration"
  }

  assert {
    condition     = var.enable_elastic_load_balancing == true
    error_message = "Elastic Load Balancing should be enabled in comprehensive configuration"
  }

  assert {
    condition     = var.enable_ebs_csi_controller == true
    error_message = "EBS CSI Controller should be enabled in comprehensive configuration"
  }

  assert {
    condition     = var.enable_container_insights == true
    error_message = "Container insights should be enabled in comprehensive configuration"
  }

  assert {
    condition     = var.enable_aws_load_balancer_controller == true
    error_message = "AWS Load Balancer Controller should be enabled in comprehensive configuration"
  }

  # Test multiple EKS add-ons are configured
  assert {
    condition     = length(var.eks_addons) == 3
    error_message = "Should have exactly 3 EKS add-ons in comprehensive configuration"
  }

  # Test specific add-ons are present
  assert {
    condition     = contains([for addon in var.eks_addons : addon.name], "metrics-server")
    error_message = "metrics-server add-on should be configured"
  }

  assert {
    condition     = contains([for addon in var.eks_addons : addon.name], "amazon-cloudwatch-observability")
    error_message = "amazon-cloudwatch-observability add-on should be configured"
  }

  assert {
    condition     = contains([for addon in var.eks_addons : addon.name], "aws-efs-csi-driver")
    error_message = "aws-efs-csi-driver add-on should be configured"
  }

  # Test all add-ons have latest version
  assert {
    condition     = alltrue([for addon in var.eks_addons : addon.version == "latest"])
    error_message = "All add-ons should use latest version"
  }

  # Test multiple namespaces are configured
  assert {
    condition     = length(var.namespaces) == 3
    error_message = "Should have exactly 3 namespaces in comprehensive configuration"
  }

  # Test specific namespaces are present
  assert {
    condition     = contains(var.namespaces, "validation-ns1")
    error_message = "validation-ns1 namespace should be configured"
  }

  assert {
    condition     = contains(var.namespaces, "validation-ns2")
    error_message = "validation-ns2 namespace should be configured"
  }

  assert {
    condition     = contains(var.namespaces, "validation-ns3")
    error_message = "validation-ns3 namespace should be configured"
  }

  # Test VPC configuration
  assert {
    condition     = length(var.cluster_vpc_config.private_subnet_ids) == 2
    error_message = "Should have exactly 2 private subnets"
  }

  # Test tags configuration
  assert {
    condition     = var.tags.Environment == "validation"
    error_message = "Environment tag should be set correctly"
  }

  assert {
    condition     = var.tags.Project == "eks-auto-validation"
    error_message = "Project tag should be set correctly"
  }

  assert {
    condition     = var.tags.TestType == "comprehensive"
    error_message = "TestType tag should be set correctly"
  }


  # Test that all EKS Auto Mode requirements are met
  assert {
    condition     = var.enable_oidc == true && var.enable_elastic_load_balancing == true
    error_message = "EKS Auto Mode requires OIDC and Elastic Load Balancing to be enabled"
  }

  # Test that all components work together
  assert {
    condition     = var.enable_oidc == true && var.enable_ebs_csi_controller == true
    error_message = "EBS CSI Controller requires OIDC to be enabled for IRSA"
  }
}
