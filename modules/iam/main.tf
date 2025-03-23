##############################
# AWS Data Sources
##############################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

##############################
# IAM Role for EKS Cluster
##############################

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-eks"

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

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  ])

  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

##############################
# IAM Role for EKS Fargate
##############################

resource "aws_iam_role" "eks_fargate" {
  name = "${var.cluster_name}-fargate"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])

  role       = aws_iam_role.eks_fargate.name
  policy_arn = each.value
}

##############################
# Custom Inline Policies for Fargate
##############################

resource "aws_iam_role_policy" "eks_fargate" {
  role = aws_iam_role.eks_fargate.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EKSFargateClusterAccess",
        Effect = "Allow",
        Action = [
          "eks:AccessKubernetesApi",
          "eks:DescribeFargateProfile",
          "eks:ListFargateProfiles",
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowECRPull",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        Resource = "*"
      },
      {
        Sid      = "AllowSecretsManagerAccess",
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:eks/*"
      },
      {
        Sid      = "AllowKMSDecrypt",
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_fargate_logging" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name = "EKSFargateLogging"
  role = aws_iam_role.eks_fargate.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "CreateLogGroup",
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/logs"
      },
      {
        Sid    = "StreamAndPutLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/logs:*"
      }
    ]
  })
}

##############################
# IAM Role for EKS Auto Mode Nodes
##############################

resource "aws_iam_role" "eks_auto_nodes" {
  name = "${var.cluster_name}-eks-auto-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eks_auto_nodes" {
  name = "${var.cluster_name}-eks-auto-nodes"
  role = aws_iam_role.eks_auto_nodes.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowMinimalWorkerNodeAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowContainerRegistryPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}
