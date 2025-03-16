# Add EKS-required subnet tags
resource "aws_ec2_tag" "eks_private_subnet_tags" {
  count = length(var.vpc.private_subnets)

  resource_id = var.vpc.private_subnets[count.index].id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [for subnet in var.vpc.private_subnets : subnet.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
