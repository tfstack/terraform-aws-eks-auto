############################################
# Provider Configuration
############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "kubernetes" {
  host                   = module.eks_auto.eks_cluster_endpoint
  cluster_ca_certificate = module.eks_auto.eks_cluster_ca_cert
  token                  = module.eks_auto.eks_cluster_auth_token
}

############################################
# Random Suffix for Resource Names
############################################

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

############################################
# Data Sources
############################################

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com/"
}

############################################
# Local Variables
############################################

locals {
  name      = "cltest"
  base_name = "${local.name}-${local.suffix}"
  suffix    = random_string.suffix.result

  eks_cluster_version = "1.33"

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

############################################
# VPC Configuration
############################################

module "vpc" {
  source = "cloudbuildlab/vpc/aws"

  vpc_name           = local.base_name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Enable Internet Gateway & NAT Gateway
  create_igw       = true
  nat_gateway_type = "single"

  enable_eks_tags  = true
  eks_cluster_name = local.name

  tags = local.tags
}

module "eks_auto" {
  source = "../.."

  ############################################
  # General Config
  ############################################
  vpc_id          = module.vpc.vpc_id
  cluster_name    = local.name
  cluster_version = local.eks_cluster_version

  tags               = local.tags
  cluster_node_pools = ["general-purpose", "system"]

  ############################################
  # Networking
  ############################################
  cluster_vpc_config = {
    private_subnet_ids   = module.vpc.private_subnet_ids
    private_access_cidrs = module.vpc.private_subnet_cidrs
    public_access_cidrs = [
      "${trimspace(data.http.my_public_ip.response_body)}/32"
    ] # exercise with cautious

    security_group_ids      = []
    endpoint_private_access = true
    endpoint_public_access  = true # exercise with cautious
  }

  ############################################
  # Logging & Monitoring
  ############################################
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  fluentbit_namespace = "aws-observability"
  fluentbit_sa_name   = "fluent-bit"

  enable_cluster_encryption           = false
  enable_elastic_load_balancing       = true
  enable_oidc                         = true
  enable_ebs_csi_controller           = true
  enable_container_insights           = true
  enable_aws_load_balancer_controller = true
  eks_log_prevent_destroy             = false
  eks_log_retention_days              = 1

  ############################################
  # Namespaces
  ############################################

  namespaces = [
    "aws-observability", # Required for Container Insights (EKS Auto Mode)
  ]

  ############################################
  # EKS Add-ons (Auto Mode)
  ############################################
  # Note: vpc-cni, kube-proxy, coredns, and eks-pod-identity-agent
  # are managed by AWS in EKS Auto Mode - do not install them
  eks_addons = [
    # Essential for monitoring and observability
    {
      name    = "metrics-server"
      version = "latest"
    },
    # CloudWatch observability and container insights
    {
      name    = "amazon-cloudwatch-observability"
      version = "latest"
    },
    # Certificate management for TLS/SSL
    {
      name    = "cert-manager"
      version = "latest"
    },
    # Log collection and forwarding
    {
      name    = "fluent-bit"
      version = "latest"
    },
    # Storage: EFS CSI driver for shared file systems
    {
      name    = "aws-efs-csi-driver"
      version = "latest"
    }
    # Note: EBS CSI driver is already integrated into EKS Auto Mode
    # Mountpoint for Amazon S3 CSI Driver is not available as an EKS add-on yet
    # Other add-ons like Secrets Manager CSI driver and Calico are typically
    # deployed via Helm charts or require special implementation
  ]
}

# Internet-facing ALB workload
module "hello_world" {
  source = "../../modules/workload"

  name             = "hello-world"
  create_namespace = true
  namespace        = "hello-world"
  replicas         = 2
  create_service   = true
  create_ingress   = true
  ingress_scheme   = "internet-facing"

  containers = [{
    name  = "hello-world"
    image = "nginx:1.25"
  }]

  service_ports = [{
    name        = "http"
    port        = 80
    target_port = 80
    protocol    = "TCP"
  }]

  ingress_rules = [{
    host = ""
    http_paths = [{
      path         = "/"
      path_type    = "Prefix"
      backend_port = 80
    }]
  }]

  ingress_annotations = {
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/load-balancer-name" = "${local.base_name}-hello-world"
  }

  cluster_name = local.name
  tags         = local.tags

  depends_on = [
    module.eks_auto,
    module.vpc
  ]
}

# Internal ALB workload
module "hello_world_internal" {
  source = "../../modules/workload"

  name             = "hello-world-internal"
  create_namespace = true
  namespace        = "hello-world-internal"
  replicas         = 1
  create_service   = true
  create_ingress   = true
  ingress_scheme   = "internal"

  containers = [{
    name  = "hello-world"
    image = "nginx:1.25"
  }]

  service_ports = [{
    name        = "http"
    port        = 80
    target_port = 80
    protocol    = "TCP"
  }]

  ingress_rules = [{
    host = ""
    http_paths = [{
      path         = "/"
      path_type    = "Prefix"
      backend_port = 80
    }]
  }]

  ingress_annotations = {
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/load-balancer-name" = "${local.base_name}-hello-world-internal"
    "alb.ingress.kubernetes.io/scheme"             = "internal"
  }

  cluster_name = local.name
  tags         = local.tags

  depends_on = [
    module.eks_auto,
    module.vpc
  ]
}

############################################
# Outputs
############################################

output "hello_world_alb_url" {
  description = "ALB URL for the hello-world internet-facing workload"
  value       = module.hello_world.alb_url
}

output "hello_world_alb_dns" {
  description = "ALB DNS name for the hello-world internet-facing workload"
  value       = module.hello_world.alb_dns_name
}

output "hello_world_internal_alb_url" {
  description = "ALB URL for the hello-world internal workload"
  value       = module.hello_world_internal.alb_url
}

output "hello_world_internal_alb_dns" {
  description = "ALB DNS name for the hello-world internal workload"
  value       = module.hello_world_internal.alb_dns_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = module.eks_auto.eks_cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version used by the EKS cluster"
  value       = module.eks_auto.cluster_version
}
