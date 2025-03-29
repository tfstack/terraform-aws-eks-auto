#########################################
# IAM Role and Policy for Fluent Bit (IRSA)
#########################################

resource "aws_iam_role" "fluentbit_irsa" {
  count = var.enable_container_insights ? 1 : 0

  name = "${var.cluster_name}-fluentbit-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.fluentbit_sa_namespace}:${var.fluentbit_sa_name}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "fluentbit_logs" {
  count = var.enable_container_insights ? 1 : 0

  name        = "${var.cluster_name}-fluentbit-logs"
  description = "Fluent Bit access to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluentbit_attach" {
  count = var.enable_container_insights ? 1 : 0

  role       = aws_iam_role.fluentbit_irsa[0].name
  policy_arn = aws_iam_policy.fluentbit_logs[0].arn
}
