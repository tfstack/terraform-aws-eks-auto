#########################################
# Hello World Self-Contained Example
#########################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

#########################################
# Providers
#########################################

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.hello_world.cluster_endpoint
  cluster_ca_certificate = base64decode(module.hello_world.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = module.hello_world.cluster_endpoint
    cluster_ca_certificate = base64decode(module.hello_world.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.hello_world.cluster_name
}

#########################################
# Hello World Module
#########################################

module "hello_world" {
  source = "../../modules/hello-world"

  name = var.name

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  kubernetes_version = var.kubernetes_version
  node_desired_size  = var.node_desired_size
  node_max_size      = var.node_max_size
  node_min_size      = var.node_min_size

  replicas = var.replicas
  image    = var.image
  port     = var.port

  tags = var.tags
}

#########################################
# Outputs
#########################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.hello_world.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.hello_world.cluster_endpoint
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = module.hello_world.alb_url
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = module.hello_world.kubeconfig_command
}
