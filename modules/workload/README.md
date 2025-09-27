# Workload Module

This Terraform module creates a complete Kubernetes workload deployment on Amazon EKS, including deployment, service, ingress, and optional IRSA (IAM Roles for Service Accounts) configuration.

## Features

- **Kubernetes Deployment**: Deploy containerized applications with configurable replicas
- **Service**: Create ClusterIP, NodePort, or LoadBalancer services
- **Ingress**: AWS Application Load Balancer (ALB) integration with internet-facing or internal schemes
- **IRSA Support**: IAM Roles for Service Accounts for secure AWS API access
- **ConfigMaps**: Create and mount configuration data
- **Volumes**: Support for ConfigMap, Secret, and EmptyDir volumes
- **Init Containers**: Run initialization containers before main containers
- **Namespace Management**: Optional namespace creation with metadata
- **Resource Management**: CPU and memory limits/requests for containers

## Usage

### Basic Example

```hcl
module "my_workload" {
  source = "./modules/workload"

  name             = "my-app"
  namespace        = "production"
  create_namespace = true
  replicas         = 3

  containers = [{
    name  = "app"
    image = "nginx:1.25"
    resources = {
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
    }
  }]

  create_service = true
  service_ports = [{
    name        = "http"
    port        = 80
    target_port = 80
    protocol    = "TCP"
  }]

  create_ingress = true
  ingress_scheme = "internet-facing"
  ingress_rules = [{
    host = ""
    http_paths = [{
      path         = "/"
      path_type    = "Prefix"
      backend_port = 80
    }]
  }]

  cluster_name = "my-eks-cluster"
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### With IRSA (IAM Roles for Service Accounts)

```hcl
module "s3_workload" {
  source = "./modules/workload"

  name             = "s3-app"
  namespace        = "data"
  create_namespace = true

  containers = [{
    name  = "app"
    image = "my-app:latest"
    env = [
      {
        name  = "AWS_REGION"
        value = "us-west-2"
      }
    ]
  }]

  irsa = {
    enabled           = true
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/ABCDEF1234567890"
    policy_arns       = ["arn:aws:iam::123456789012:policy/MyS3Policy"]
  }

  service_account_name = "s3-service-account"

  cluster_name = "my-eks-cluster"
}
```

### With ConfigMaps and Volumes

```hcl
module "config_workload" {
  source = "./modules/workload"

  name             = "config-app"
  namespace        = "config"
  create_namespace = true

  configmaps = [
    {
      name = "app-config"
      data = {
        DATABASE_URL = "postgresql://localhost:5432/mydb"
        LOG_LEVEL    = "info"
      }
    }
  ]

  containers = [{
    name  = "app"
    image = "my-app:latest"
    volume_mounts = [
      {
        name       = "config-volume"
        mount_path = "/app/config"
      }
    ]
  }]

  volumes = [
    {
      name = "config-volume"
      config_map = {
        name = "app-config"
      }
    }
  ]

  cluster_name = "my-eks-cluster"
}
```

### Internal ALB Example

```hcl
module "internal_workload" {
  source = "./modules/workload"

  name             = "internal-api"
  namespace        = "internal"
  create_namespace = true

  containers = [{
    name  = "api"
    image = "my-api:latest"
  }]

  create_service = true
  service_ports = [{
    name        = "http"
    port        = 8080
    target_port = 8080
  }]

  create_ingress = true
  ingress_scheme = "internal"
  ingress_annotations = {
    "alb.ingress.kubernetes.io/scheme" = "internal"
  }
  ingress_rules = [{
    host = ""
    http_paths = [{
      path         = "/api"
      path_type    = "Prefix"
      backend_port = 8080
    }]
  }]

  cluster_name = "my-eks-cluster"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| kubernetes | >= 2.20 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| kubernetes | >= 2.20 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the workload | `string` | n/a | yes |
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| namespace | Kubernetes namespace for the workload | `string` | `"default"` | no |
| create_namespace | Whether to create the namespace | `bool` | `false` | no |
| replicas | Number of replicas for the deployment | `number` | `1` | no |
| labels | Additional labels to apply to resources | `map(string)` | `{}` | no |
| namespace_metadata | Metadata for the namespace (labels and annotations) | `object({ labels = optional(map(string), {}), annotations = optional(map(string), {}) })` | `{}` | no |
| service_account_name | Name of the service account (defaults to workload name if not specified) | `string` | `null` | no |
| irsa | IRSA configuration for the workload | `object({ enabled = bool, oidc_provider_arn = string, policy_arns = optional(list(string), []) })` | `{ enabled = false, oidc_provider_arn = "", policy_arns = [] }` | no |
| containers | List of containers for the workload | `list(object({ name = string, image = string, command = optional(list(string), null), args = optional(list(string), null), env = optional(list(object({ name = string, value = string })), []), resources = optional(object({ limits = optional(map(string), {}), requests = optional(map(string), {}) }), null), volume_mounts = optional(list(object({ name = string, mount_path = string })), []) }))` | `[]` | no |
| init_containers | List of init containers for the workload | `list(object({ name = string, image = string, command = optional(list(string), null), args = optional(list(string), null), env = optional(list(object({ name = string, value = string })), []), volume_mounts = optional(list(object({ name = string, mount_path = string })), []) }))` | `[]` | no |
| volumes | List of volumes for the workload | `list(object({ name = string, config_map = optional(object({ name = string }), null), secret = optional(object({ secret_name = string }), null) }))` | `[]` | no |
| configmaps | List of ConfigMaps for the workload | `list(object({ name = string, data = map(string) }))` | `[]` | no |
| create_service | Whether to create a Kubernetes service | `bool` | `true` | no |
| service_type | Type of Kubernetes service | `string` | `"ClusterIP"` | no |
| service_ports | List of ports for the service | `list(object({ name = string, port = number, target_port = number, protocol = optional(string, "TCP") }))` | `[]` | no |
| service_annotations | Annotations for the service | `map(string)` | `{}` | no |
| logging | Logging configuration for the workload | `object({ enabled = bool })` | `{ enabled = false }` | no |
| create_ingress | Whether to create an Ingress resource | `bool` | `false` | no |
| ingress_scheme | ALB scheme - 'internet-facing' for external or 'internal' for internal | `string` | `"internet-facing"` | no |
| ingress_protocol | Protocol for the ALB URL - 'http' or 'https' | `string` | `"http"` | no |
| ingress_annotations | Annotations for the Ingress resource | `map(string)` | `{}` | no |
| ingress_rules | Rules for the Ingress resource | `list(object({ host = string, http_paths = list(object({ path = string, path_type = optional(string, "Prefix"), backend_port = number })) }))` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| deployment_name | Name of the Kubernetes deployment |
| deployment_namespace | Namespace of the Kubernetes deployment |
| service_name | Name of the Kubernetes service |
| service_namespace | Namespace of the Kubernetes service |
| service_account_name | Name of the Kubernetes service account |
| service_account_namespace | Namespace of the Kubernetes service account |
| irsa_role_arn | ARN of the IAM role for IRSA |
| namespace_name | Name of the created namespace |
| ingress_name | Name of the Kubernetes ingress |
| ingress_namespace | Namespace of the Kubernetes ingress |
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_url | URL of the Application Load Balancer |

## ALB Ingress Annotations

The module automatically sets several ALB ingress annotations for optimal configuration:

- `kubernetes.io/ingress.class`: Set to "alb"
- `alb.ingress.kubernetes.io/scheme`: Set based on `ingress_scheme` variable
- `alb.ingress.kubernetes.io/group.name`: Set to workload name for grouping
- `alb.ingress.kubernetes.io/manage-backend-security-group-rules`: Set to "false"

You can override these or add additional annotations via the `ingress_annotations` variable.

## Common ALB Annotations

Here are some commonly used ALB annotations you can add via `ingress_annotations`:

```hcl
ingress_annotations = {
  "alb.ingress.kubernetes.io/target-type"                    = "ip"
  "alb.ingress.kubernetes.io/load-balancer-name"             = "my-custom-alb"
  "alb.ingress.kubernetes.io/healthcheck-path"               = "/health"
  "alb.ingress.kubernetes.io/healthcheck-interval-seconds"   = "15"
  "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"    = "5"
  "alb.ingress.kubernetes.io/healthy-threshold-count"        = "2"
  "alb.ingress.kubernetes.io/unhealthy-threshold-count"      = "3"
  "alb.ingress.kubernetes.io/listen-ports"                   = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
  "alb.ingress.kubernetes.io/ssl-redirect"                   = "443"
  "alb.ingress.kubernetes.io/certificate-arn"                = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}
```

## Dependencies

This module depends on:

1. **AWS Load Balancer Controller**: Must be installed in the EKS cluster for ALB ingress functionality
2. **EKS Cluster**: The target EKS cluster must exist and be accessible
3. **OIDC Provider**: Required for IRSA functionality (if enabled)

## Security Considerations

- **IRSA**: Use IAM Roles for Service Accounts instead of hardcoded AWS credentials
- **Resource Limits**: Always set appropriate CPU and memory limits for containers
- **Network Policies**: Consider implementing Kubernetes Network Policies for additional security
- **RBAC**: Ensure proper RBAC configuration for service accounts
- **Secrets**: Use Kubernetes Secrets or external secret management for sensitive data

## Troubleshooting

### Common Issues

1. **ALB Not Created**: Ensure AWS Load Balancer Controller is installed and running
2. **IRSA Not Working**: Verify OIDC provider ARN and trust relationship
3. **Service Not Accessible**: Check service ports and ingress rules configuration
4. **Namespace Issues**: Ensure proper permissions to create namespaces

### Debugging

Check the status of resources:

```bash
# Check deployment status
kubectl get deployment -n <namespace> <workload-name>

# Check service status
kubectl get service -n <namespace> <workload-name>

# Check ingress status
kubectl get ingress -n <namespace> <workload-name>

# Check ALB status
kubectl describe ingress -n <namespace> <workload-name>
```

## License

This module is part of the terraform-aws-eks-auto project. See the main project for license information.
