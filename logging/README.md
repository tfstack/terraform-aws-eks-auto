# Terraform EKS Fluent Bit Logging Module

This Terraform module provisions Kubernetes resources to enable **Fluent Bit logging** on AWS EKS Fargate, pushing logs to **Amazon CloudWatch Logs**.

## Features

- ✅ Creates a dedicated `aws-observability` Kubernetes namespace
- ✅ Deploys a ConfigMap with Fluent Bit `filters`, `outputs`, and `parsers`
- ✅ Integrates with EKS Fargate profiles
- ✅ Configurable log retention and cluster name

---

## Usage Example

```hcl
# Provide cluster name and log retention days
variable "cluster_name" {
  default = "example-cluster"
}

variable "eks_log_retention_days" {
  default = 30
}

module "eks_logging" {
  source = "../.."

  cluster_name           = var.cluster_name
  eks_log_retention_days = var.eks_log_retention_days
}

# Outputs
output "namespace" {
  value = module.eks_logging.logging_namespace_name
}

output "configmap" {
  value = module.eks_logging.logging_configmap_name
}
```

---

## Inputs

| Name                   | Type     | Default | Description                                               |
|------------------------|----------|---------|-----------------------------------------------------------|
| `cluster_name`         | `string` | —       | **(Required)** Name of the EKS cluster                    |
| `eks_log_retention_days` | `number` | `30`     | Number of days to retain logs in CloudWatch Logs         |

---

## Outputs

| Name                       | Description                                                      |
|----------------------------|------------------------------------------------------------------|
| `logging_namespace_name`   | The Kubernetes namespace used for Fluent Bit logging             |
| `logging_configmap_name`   | The name of the ConfigMap for Fluent Bit configuration           |
| `eks_fargate_log_group_name` | The name of the CloudWatch Logs group used for EKS Fargate logs |

---

## Deployment

### Initialize Terraform

```sh
terraform init
```

### Apply Configuration

```sh
terraform apply -auto-approve
```

### View Outputs

```sh
terraform output
```

### Destroy Resources

```sh
terraform destroy -auto-approve
```

---

## Notes

- This module assumes Fluent Bit is deployed and configured as part of your Fargate logging setup.
- Ensure your EKS Fargate IAM role has permission to write to CloudWatch Logs.

---

## License

This module is released under the **MIT License**.
