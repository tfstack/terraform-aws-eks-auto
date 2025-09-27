#########################################
# Kubernetes Service Account for EBS CSI (IRSA)
#########################################

resource "kubernetes_service_account" "ebs_csi_controller" {
  count = var.enable_ebs_csi_controller ? 1 : 0

  metadata {
    name      = var.ebs_csi_controller_sa_name
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_controller_irsa[0].arn
    }
  }
}
