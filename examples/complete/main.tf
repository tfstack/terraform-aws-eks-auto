############################################
# Provider Configuration
############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
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
  base_name = "${local.name}-${random_string.suffix.result}"

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

  enable_cluster_encryption     = false
  enable_elastic_load_balancing = true
  enable_oidc                   = true
  enable_ebs_csi_controller     = true
  enable_container_insights     = true
  enable_prometheus             = true
  eks_log_prevent_destroy       = false
  eks_log_retention_days        = 1

  ############################################
  # Namespaces
  ############################################

  namespaces = [
    "aws-observability", # Required for Container Insights (EKS Auto Mode)
    "prometheus"         # Required for Prometheus monitoring
  ]

  ############################################
  # EKS Add-ons (Auto Mode)
  ############################################
  # Note: vpc-cni, kube-proxy, coredns, and eks-pod-identity-agent
  # are managed by AWS in EKS Auto Mode - do not install them
  eks_addons = [
    {
      name    = "metrics-server"
      version = "latest"
    }
    # Add other non-networking add-ons as needed:
    # - CloudWatch Agent
    # - external-dns
    # - etc.
  ]

  # AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true

  ############################################
  # Workloads
  ############################################
  workloads = [
    {
      name      = "hello-world"
      namespace = "default"
      replicas  = 3
      labels = {
        environment = "dev"
        app         = "hello-world"
      }
      containers = [
        {
          name  = "hello-world"
          image = "nginx:1.25"
          env = [
            {
              name  = "MESSAGE"
              value = "Hello from EKS Auto Mode with Load Balancer!"
            }
          ]
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      ]
      service_ports = [
        {
          name        = "http"
          port        = 80
          target_port = 80
          protocol    = "TCP"
        }
      ]
      service_type   = "ClusterIP"
      create_ingress = true
      ingress_scheme = "internet-facing" # Use "internal" for internal ALB
      ingress_annotations = {
        "kubernetes.io/ingress.class"                            = "alb"
        "alb.ingress.kubernetes.io/target-type"                  = "ip"
        "alb.ingress.kubernetes.io/load-balancer-name"           = "hello-world-alb"
        "alb.ingress.kubernetes.io/healthcheck-path"             = "/"
        "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
        "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
        "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
        "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"
      }
      ingress_rules = [
        {
          host = ""
          http_paths = [
            {
              path         = "/"
              path_type    = "Prefix"
              backend_port = 80
            }
          ]
        }
      ]
      logging = {
        enabled = true
      }
    }
  ]
}

output "all_module_outputs" {
  description = "All outputs from the EKS Auto module"
  value       = module.eks_auto
}
