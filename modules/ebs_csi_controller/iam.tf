#########################################
# IRSA Role for EBS CSI Controller
#########################################

resource "aws_iam_role" "ebs_csi_controller_irsa" {
  count = var.enable_ebs_csi_controller ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-controller-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:${var.ebs_csi_controller_sa_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-ebs-csi-controller-irsa" })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_controller_policy" {
  count = var.enable_ebs_csi_controller ? 1 : 0

  role       = aws_iam_role.ebs_csi_controller_irsa[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy" "ebs_csi_controller_extra" {
  count = var.enable_ebs_csi_controller ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-controller-extra"
  role = aws_iam_role.ebs_csi_controller_irsa[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFullEBSActionsOnClusterInstances"
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}
