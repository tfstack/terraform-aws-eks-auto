#########################################
# CloudWatch Log Group for Fluent Bit Logs
#########################################

resource "aws_cloudwatch_log_group" "fluentbit_logs_with_prevent_destroy" {
  count = var.enable_container_insights && var.eks_log_prevent_destroy ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/fluent-bit"
  retention_in_days = var.eks_log_retention_days

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-fluentbit-logs"
  }
}

resource "aws_cloudwatch_log_group" "fluentbit_logs_without_prevent_destroy" {
  count = var.enable_container_insights && !var.eks_log_prevent_destroy ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/fluent-bit"
  retention_in_days = var.eks_log_retention_days

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.cluster_name}-fluentbit-logs"
  }
}
