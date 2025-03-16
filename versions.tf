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
  }
}

provider "kubernetes" {
  host                   = module.cluster.eks_cluster_endpoint
  cluster_ca_certificate = module.cluster.eks_cluster_ca_cert
  token                  = module.cluster.eks_cluster_auth_token
}

provider "helm" {
  kubernetes = {
    host                   = module.cluster.eks_cluster_endpoint
    cluster_ca_certificate = module.cluster.eks_cluster_ca_cert
    token                  = module.cluster.eks_cluster_auth_token
  }
}
