terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.eks_cluster_endpoint
  cluster_ca_certificate = module.eks.eks_cluster_ca_cert
  token                  = module.eks.eks_cluster_auth_token
}

# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.this.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.this.token
#   }
# }
