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
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  host                   = module.cluster.eks_cluster_endpoint
  cluster_ca_certificate = module.cluster.eks_cluster_ca_cert
  token                  = module.cluster.eks_cluster_auth_token

  # Handle cluster deletion gracefully
  ignore_annotations = [
    "helm.sh/hook",
    "helm.sh/hook-weight",
    "helm.sh/hook-delete-policy"
  ]

  # Use exec for more robust cluster connectivity
  # This will automatically handle cluster deletion gracefully
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.cluster.eks_cluster_endpoint
    cluster_ca_certificate = module.cluster.eks_cluster_ca_cert
    token                  = module.cluster.eks_cluster_auth_token
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
    }
  }
}
