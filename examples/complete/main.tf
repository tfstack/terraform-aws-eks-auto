############################################
# Provider Configuration
############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

############################################
# Random Suffix for Resource Names
############################################

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

############################################
# Data Sources
############################################

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

data "http" "my_public_ip" {
  url = "http://ifconfig.me/ip"
}

############################################
# Local Variables
############################################

locals {
  name      = "cltest"
  base_name = "${local.name}-${random_string.suffix.result}"

  eks_cluster_version = "1.32"

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

############################################
# VPC Configuration
############################################

module "vpc" {
  source = "tfstack/vpc/aws"

  vpc_name           = local.base_name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  eic_subnet        = "jumphost"
  eic_ingress_cidrs = ["${data.http.my_public_ip.response_body}/32"]

  jumphost_subnet              = "10.0.0.0/24"
  jumphost_allow_egress        = false
  jumphost_instance_create     = false
  jumphost_user_data_file      = "${path.module}/external/cloud-init.sh"
  jumphost_log_prevent_destroy = false

  create_igw = true
  ngw_type   = "single"

  tags = local.tags

  enable_eks_tags = true
}

############################################
# ECS Cluster Configuration
############################################

data "aws_eks_addon_version" "latest" {
  addon_name         = "vpc-cni"
  kubernetes_version = local.eks_cluster_version
  most_recent        = true
}

module "eks_auto" {
  source = "../.."

  ############################################
  # General Config
  ############################################
  vpc_id                        = module.vpc.vpc_id
  cluster_name                  = local.name
  cluster_version               = local.eks_cluster_version
  tags                          = local.tags
  node_pools                    = ["general-purpose"]
  enable_executor_cluster_admin = true

  ############################################
  # Networking
  ############################################
  cluster_vpc_config = {
    private_subnet_ids   = module.vpc.private_subnet_ids
    private_access_cidrs = module.vpc.private_subnet_cidrs
    public_access_cidrs = [
      "${data.http.my_public_ip.response_body}/32"
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

  enable_cluster_encryption     = false
  enable_elastic_load_balancing = true
  eks_log_prevent_destroy       = false
  eks_log_retention_days        = 1

  ############################################
  # Addons
  ############################################
  eks_addons = [
    { name = "kube-proxy", version = "v1.32.0-eksbuild.2" },
    { name = "vpc-cni", version = "v1.19.2-eksbuild.5" },
    { name = "eks-pod-identity-agent", version = "v1.3.4-eksbuild.1" }
  ]

  ############################################
  # Fargate Profiles
  ############################################
  fargate_profiles = {
    default = {
      enabled   = true
      namespace = "default"
    }
    logging = {
      enabled   = true
      namespace = "logging"
    }
    monitoring = {
      enabled   = false
      namespace = "monitoring"
    }
    kube_system = {
      enabled   = true
      namespace = "kube-system"
    }
  }

  ############################################
  # EKS View Access
  ############################################
  # eks_view_access = {
  #   enabled = true
  #   role_names = [
  #     "${local.base_name}-jumphost"
  #   ]
  # }

  ############################################
  # Apps
  ############################################
  apps = [
    {
      name             = "hello-world"
      image            = "public.ecr.aws/nginx/nginx:latest"
      port             = 80
      namespace        = "default"
      create_namespace = false
      enable_logging   = true
    },
    {
      name  = "nginx"
      image = "nginx:1.25"
      port  = 8080

      labels = {
        env = "dev"
      }

      healthcheck = {
        liveness = {
          http_get = {
            path = "/"
            port = 8080
          }
          initial_delay_seconds = 5
          period_seconds        = 10
        }

        readiness = {
          http_get = {
            path = "/"
            port = 8080
          }
          initial_delay_seconds = 3
          period_seconds        = 5
        }
      }
    },
    {
      name           = "webapp"
      image          = "nginx:latest"
      port           = 80
      enable_logging = true

      autoscaling = {
        enabled                           = true
        min_replicas                      = 2
        max_replicas                      = 5
        target_cpu_utilization_percentage = 60
      }
    }
  ]
}

output "all_module_outputs" {
  description = "All outputs from the EKS Auto module"
  value       = module.eks_auto
}
