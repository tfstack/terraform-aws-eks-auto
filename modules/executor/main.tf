data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  executor_role_name = split("/", data.aws_caller_identity.current.arn)[1]
}

data "aws_iam_role" "terraform_executor" {
  name = split("/", data.aws_caller_identity.current.arn)[1]
}

resource "aws_eks_access_entry" "terraform_executor" {
  count = var.enable_executor_cluster_admin ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.executor_role_name}"
}

resource "aws_eks_access_policy_association" "terraform_executor" {
  count = var.enable_executor_cluster_admin ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.terraform_executor[0].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "null_resource" "wait_for_kubernetes_api" {
  count = var.enable_k8s_api_wait ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Kubernetes API to become accessible..."

      for attempt in $(seq 1 ${var.k8s_api_wait_attempts}); do
        token=$(aws eks get-token --cluster-name ${var.cluster_name} --region ${data.aws_region.current.name} --output text --query 'status.token' 2>/dev/null)

        if [ -z "$token" ]; then
          echo "[Attempt $attempt] Unable to retrieve token. Retrying..."
        else
          code=$(curl -sSk -o /dev/null -w "%%{http_code}" \
            -H "Authorization: Bearer $token" \
            ${var.eks_cluster_endpoint}/healthz 2>/dev/null)

          if [ "$code" = "200" ]; then
            echo "Kubernetes API is ready (HTTP 200)."
            exit 0
          else
            echo "[Attempt $attempt] API not ready (HTTP $code). Retrying..."
          fi
        fi

        sleep ${var.k8s_api_wait_interval}
      done

      echo "Timed out waiting for Kubernetes API readiness."
      exit 1
    EOT
  }

  depends_on = [
    aws_eks_access_policy_association.terraform_executor
  ]
}

# resource "kubernetes_config_map" "aws_auth_executor" {
#   count = var.patch_aws_auth ? 1 : 0

#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.executor_role_name}"
#         username = "terraform"
#         groups   = ["system:masters"]
#       }
#     ])
#   }

#   lifecycle {
#     ignore_changes = [data] # Avoid drift if other tools modify it
#   }

#   depends_on = [aws_eks_access_entry.terraform_executor]
# }
# variable "patch_aws_auth" {
#   description = "Whether to also patch aws-auth for compatibility with the Kubernetes provider"
#   type        = bool
#   default     = true
# }
