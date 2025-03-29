#########################################
# Kubernetes Service Account for Fluent Bit (IRSA)
#########################################

resource "kubernetes_service_account" "fluentbit" {
  count = var.enable_container_insights ? 1 : 0

  metadata {
    name      = var.fluentbit_sa_name
    namespace = var.fluentbit_sa_namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluentbit_irsa[0].arn
    }
  }
}
