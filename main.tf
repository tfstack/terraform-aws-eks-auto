resource "aws_security_group" "eks_sg" {
  vpc_id = var.vpc.id
  name   = "${var.cluster_name}-eks-sg"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc.private_subnets[0].cidr]
  }
}
