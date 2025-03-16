resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
  subnet_ids             = [for subnet in var.vpc.private_subnets : subnet.id]

  selector {
    namespace = "default"
  }
}
