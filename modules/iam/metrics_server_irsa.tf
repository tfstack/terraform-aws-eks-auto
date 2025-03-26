data "aws_iam_policy_document" "metrics_server" {
  count = var.enable_metrics_server_irsa ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.metrics_server_namespace}:${var.metrics_server_service_account}"]
    }
  }
}

resource "aws_iam_role" "metrics_server" {
  count = var.enable_metrics_server_irsa ? 1 : 0

  name               = "${var.cluster_name}-eks-metrics-server-irsa"
  assume_role_policy = data.aws_iam_policy_document.metrics_server[0].json
}
