data "aws_region" "current" {}

locals {
  cluster_log_group = (
    var.eks_log_prevent_destroy ?
    aws_cloudwatch_log_group.eks_cluster_with_prevent_destroy[0] :
    aws_cloudwatch_log_group.eks_cluster_without_prevent_destroy[0]
  )

  logs_log_group = (
    var.eks_log_prevent_destroy ?
    aws_cloudwatch_log_group.eks_logs_with_prevent_destroy[0] :
    aws_cloudwatch_log_group.eks_logs_without_prevent_destroy[0]
  )
}
