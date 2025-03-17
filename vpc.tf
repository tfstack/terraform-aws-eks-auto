resource "aws_security_group" "eks" {
  count = var.create_security_group ? 1 : 0

  vpc_id = var.vpc_id
  name   = "${var.cluster_name}-eks"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cluster_vpc_config.public_access_cidrs
    description = "Allow API access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    description = "Allow worker nodes to communicate with API server"
  }

  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.cluster_vpc_config.private_access_cidrs
    description = "Allow Kubernetes cluster networking"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}
