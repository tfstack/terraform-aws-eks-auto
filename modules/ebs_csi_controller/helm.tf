#########################################
# Helm Chart for AWS EBS CSI Driver
#########################################

resource "helm_release" "ebs_csi_driver" {
  count = var.enable_ebs_csi_controller ? 1 : 0

  name             = "aws-ebs-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  version          = local.ebs_csi_driver_version
  namespace        = "kube-system"
  create_namespace = false

  values = [yamlencode({
    controller = {
      serviceAccount = {
        create = false
        name   = var.ebs_csi_controller_sa_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_controller_irsa[0].arn
        }
      }
    }

    node = {
      tolerateAllTaints = true
      tolerations = [
        {
          operator = "Exists"
        }
      ]
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "kubernetes.io/os"
                    operator = "In"
                    values   = ["linux"]
                  }
                ]
              }
            ]
          }
        }
      }
    }
  })]

  depends_on = [
    kubernetes_service_account.ebs_csi_controller
  ]
}
