#########################################
# TLS Certificate for EKS OIDC (IRSA)
#########################################

data "tls_certificate" "eks_oidc" {
  # Only needed when we need to create a new provider
  count = var.enable_oidc && var.existing_oidc_provider_arn == null ? 1 : 0

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

#########################################
# IAM OpenID Connect Provider for EKS (IRSA)
#########################################

resource "aws_iam_openid_connect_provider" "this" {
  # Create only if OIDC is enabled and no existing provider is supplied
  count = var.enable_oidc && var.existing_oidc_provider_arn == null ? 1 : 0

  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.eks_oidc[0].certificates[0].sha1_fingerprint
  ]
}

# When an existing provider ARN is passed, expose its attributes via data source
data "aws_iam_openid_connect_provider" "existing" {
  count = var.enable_oidc && var.existing_oidc_provider_arn != null ? 1 : 0

  arn = var.existing_oidc_provider_arn
}
