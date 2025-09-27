##############################
# IAM Role for EKS Auto Cluster
##############################

resource "aws_iam_role" "eks_auto_cluster" {
  name = "${var.cluster_name}-eks-auto-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_auto_cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  ])

  role       = aws_iam_role.eks_auto_cluster.name
  policy_arn = each.value
}

##############################
# IAM Role for EKS Auto Node
##############################

resource "aws_iam_role" "eks_auto_node" {
  name = "${var.cluster_name}-eks-auto-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_auto_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  ])

  role       = aws_iam_role.eks_auto_node.name
  policy_arn = each.value
}

resource "aws_iam_policy" "eks_node_ebs_support" {
  name        = "${var.cluster_name}-eks-node-ebs-access"
  description = "Permissions for EKS nodes to support EBS CSI driver volume attachments"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EBSVolumeActions",
        Effect = "Allow",
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ],
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      {
        Sid    = "DescribeAccess",
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_ebs_support_attach" {
  role       = aws_iam_role.eks_auto_node.name
  policy_arn = aws_iam_policy.eks_node_ebs_support.arn
}
